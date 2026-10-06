local addonName, Artisan = ...

Artisan.UI = Artisan.UI or {}

local ROW_HEIGHT = 21
local VISIBLE_ROWS = 20
local WHEEL_STEP = 5

local CATEGORY_ROWS_MAX = 6
local CATEGORY_ROW_HEIGHT = 15

local COLUMNS = {
    { key = "name",   text = "Рецепт",   x = 120, width = 240, align = "LEFT",  sortKey = "itemName" },
    { key = "cost",   text = "Затраты",  x = 300, width = 120, align = "RIGHT", sortKey = "cost" },
    { key = "sell",   text = "Продажа",  x = 440, width = 120, align = "RIGHT", sortKey = "sell" },
    { key = "profit", text = "Прибыль",  x = 580, width = 140, align = "RIGHT", sortKey = "profit" },
}

function Artisan.UI:CreateMainWindow()
    if ArtisanMainFrame then return end

    local frame = CreateFrame("Frame", "ArtisanMainFrame", UIParent)
    tinsert(UISpecialFrames, "ArtisanMainFrame")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN")

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture(0, 0, 0, 0.8)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
        end
    end)

    frame:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
    end)

    frame:SetScript("OnShow", function()
        Artisan.UI:InitList()
    end)

    frame:Hide()

    Artisan.UI.MainFrame = frame

    self:CreateTopBar(frame)
    self:CreateRecipeList(frame)
end

local PROFESSIONS = {
    { id = "Alchemy", name = "Алхимия", icon = "Interface\\Icons\\Trade_Alchemy" },
    { id = "Blacksmithing", name = "Кузнечное дело", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { id = "Enchanting", name = "Наложение чар", icon = "Interface\\Icons\\Trade_Engraving" },
    { id = "Engineering", name = "Инженерное дело", icon = "Interface\\Icons\\Trade_Engineering" },
    { id = "Inscription", name = "Начертание", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    { id = "Jewelcrafting", name = "Ювелирное дело", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
    { id = "Leatherworking", name = "Кожевничество", icon = "Interface\\Icons\\Trade_LeatherWorking" },
    { id = "Tailoring", name = "Портняжное дело", icon = "Interface\\Icons\\Trade_Tailoring" },
    { id = "Cooking", name = "Кулинария", icon = "Interface\\Icons\\INV_Misc_Food_15" },
    { id = "Smelting", name = "Горное дело", icon = "Interface\\Icons\\Trade_Mining" },
}

function Artisan.UI:CreateTopBar(parentFrame)
    local topBar = CreateFrame("Frame", "TopBar", parentFrame)
    topBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 5, 5)
    topBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -5, -5)
    topBar:SetHeight((CATEGORY_ROWS_MAX - 1) * CATEGORY_ROW_HEIGHT)
    self.TopBar = topBar

    for idx, prof in ipairs(PROFESSIONS) do
        local btn = CreateFrame("Button", nil, topBar)
        btn:SetPoint("LEFT", topBar, "LEFT", (idx - 1) * 32, 13)
        btn:SetSize(28, 28)

        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetSize(60, 60)
        border:SetPoint("CENTER", btn, "CENTER", 0, 0)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:Hide()

        local texture = btn:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(btn)
        texture:SetTexture(prof.icon)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        btn:SetScript("OnEnter", function(self)
            border:Show()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(prof.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            local selected = Artisan.UI.SelectedProfessions or {}
            if not selected[prof.id] then
                border:Hide()
            end
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            Artisan.UI:ToggleProfession(prof.id)
        end)

        self.ProfessionButtons = self.ProfessionButtons or {}
        self.ProfessionButtons[prof.id] = { button = btn, border = border }
    end

    local closeBtn = CreateFrame("Button", nil, parentFrame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -2)

    local text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    text:SetText("X")
    text:SetTextColor(0.6, 0.6, 0.6)

    closeBtn:SetScript("OnEnter", function() text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() text:SetTextColor(0.6, 0.6, 0.6) end)
    closeBtn:SetScript("OnClick", function() parentFrame:Hide() end)

    local categoryBar = CreateFrame("Frame", nil, topBar)
    categoryBar:SetPoint("TOPLEFT", topBar, "TOPLEFT", 330, -8)
    categoryBar:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", -10, -4)
    categoryBar:SetHeight(CATEGORY_ROWS_MAX * CATEGORY_ROW_HEIGHT)
    self.CategoryBar = categoryBar
end

function Artisan.UI:CreateRecipeList(parentFrame)
    local filterBox = CreateFrame("EditBox", nil, parentFrame, "InputBoxTemplate")
    filterBox:SetSize(280, 20)
    filterBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -40)
    filterBox:SetAutoFocus(false)
    filterBox:SetTextInsets(4, 4, 0, 0)

    local filterLabel = filterBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("LEFT", filterBox, "RIGHT", 6, 0)
    filterLabel:SetText("Поиск")
    filterLabel:SetTextColor(0.6, 0.6, 0.6)

    filterBox:SetScript("OnTextChanged", function(self)
        Artisan.UI:SetFilter(self:GetText())
    end)

    local header = CreateFrame("Frame", nil, parentFrame)
    header:SetPoint("TOPLEFT", filterBox, "BOTTOMLEFT", 0, -4)
    header:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, 0)
    header:SetHeight(20)

    local scrollFrame = CreateFrame("ScrollFrame", "ArtisanRecipeScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 10)

    self.ColumnHeaders = {}
    for _, col in ipairs(COLUMNS) do
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(col.width, 18)
        btn:SetPoint("LEFT", header, "LEFT", col.x, 0)
        btn.col = col

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetAllPoints(btn)
        txt:SetText(col.text)
        txt:SetJustifyH(col.align)
        txt:SetTextColor(0.7, 0.7, 0.7)
        btn.txt = txt

        btn:SetScript("OnEnter", function(self)
            self.txt:SetTextColor(1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            Artisan.UI:RefreshColumnHeaders()
        end)
        btn:SetScript("OnClick", function(self)
            Artisan.UI:ToggleSort(self.col.sortKey)
        end)

        self.ColumnHeaders[col.key] = btn
    end

    self.RowFrames = {}
    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, parentFrame)
        row:SetSize(750, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        if i % 2 == 0 then
            bg:SetTexture(1, 1, 1, 0.04)
        end

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.name:SetWidth(240)
        row.name:SetJustifyH("LEFT")

        row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cost:SetPoint("LEFT", row, "LEFT", 300, 0)
        row.cost:SetWidth(120)
        row.cost:SetJustifyH("RIGHT")

        row.sell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.sell:SetPoint("LEFT", row, "LEFT", 440, 0)
        row.sell:SetWidth(120)
        row.sell:SetJustifyH("RIGHT")

        row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.profit:SetPoint("LEFT", row, "LEFT", 580, 0)
        row.profit:SetWidth(140)
        row.profit:SetJustifyH("RIGHT")

        self.RowFrames[i] = row

        row:SetScript("OnEnter", function(self)
            if not self.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink("item:" .. self.data.itemID)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self, button)
            if button == "LeftButton" and IsShiftKeyDown() and self.data then
                Artisan.UI:SearchOnAuctionHouse(self.data.itemName)
            end
        end)
    end

    local scrollBar = CreateFrame("Slider", "ArtisanRecipeScrollFrameScrollBar",
        scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -20, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -20, 0)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    self.ScrollBar = scrollBar

    local function ClampOffset(offset, totalItems)
        local maxOffset = math.max(0, totalItems - VISIBLE_ROWS)
        if offset < 0 then offset = 0 end
        if offset > maxOffset then offset = maxOffset end
        return offset
    end

    local function OnWheel(delta)
        local totalItems = Artisan.UI.CurrentList and #Artisan.UI.CurrentList or 0
        local newOffset = FauxScrollFrame_GetOffset(scrollFrame) - (delta * WHEEL_STEP)
        newOffset = ClampOffset(newOffset, totalItems)
        FauxScrollFrame_SetOffset(scrollFrame, newOffset)
        Artisan.UI:UpdateScroll()
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        OnWheel(delta)
    end)

    for i = 1, VISIBLE_ROWS do
        local row = self.RowFrames[i]
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            OnWheel(delta)
        end)
    end

    scrollBar:EnableMouseWheel(true)
    scrollBar:SetScript("OnMouseWheel", function(_, delta)
        OnWheel(delta)
    end)

    scrollBar:SetScript("OnValueChanged", function(_, value)
        if FauxScrollFrame_GetOffset(scrollFrame) ~= value then
            local totalItems = Artisan.UI.CurrentList and #Artisan.UI.CurrentList or 0
            FauxScrollFrame_SetOffset(scrollFrame, ClampOffset(value, totalItems))
            Artisan.UI:UpdateScroll()
        end
    end)

    self.ScrollFrame = scrollFrame
end

function Artisan.UI:InitList()
    if not Artisan.Pricing then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Модуль Pricing не загружен. Полностью перезапусти клиент (не только /reload).")
        return
    end
    if self.Initialized then return end

    self.Initialized = true
    if not self.SortKey then
        self.SortKey = "profit"
        self.SortDir = -1
    end

    self:RebuildFullList()
    self:BuildCategoryBar()
    self:RefreshList()
    self:RefreshColumnHeaders()
end

function Artisan.UI:ToggleProfession(profID)
    if not Artisan.Pricing then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Модуль Pricing не загружен. Полностью перезапусти клиент (не только /reload).")
        return
    end

    self.SelectedProfessions = self.SelectedProfessions or {}
    if self.SelectedProfessions[profID] then
        self.SelectedProfessions[profID] = nil
    else
        self.SelectedProfessions[profID] = true
    end

    self:RefreshProfessionSelection()
    self:RebuildFullList()

    if not self.SortKey then
        self.SortKey = "profit"
        self.SortDir = -1
    end

    self.GroupFilter = nil
    self:BuildCategoryBar()
    self:RefreshList()
    self:RefreshColumnHeaders()
end

function Artisan.UI:RebuildFullList()
    local selected = self.SelectedProfessions or {}
    local profs = {}

    if next(selected) then
        for id in pairs(selected) do
            tinsert(profs, id)
        end
    else
        for _, prof in ipairs(PROFESSIONS) do
            tinsert(profs, prof.id)
        end
    end

    local list = {}
    for _, id in ipairs(profs) do
        local plist = Artisan.Pricing:GetProfessionList(id)
        if plist then
            for _, row in ipairs(plist) do
                tinsert(list, row)
            end
        end
    end

    self.FullList = list
end

function Artisan.UI:SetGroup(group)
    self.GroupFilter = group or nil
    self:RefreshList()
    self:BuildCategoryBar()
end

function Artisan.UI:RefreshProfessionSelection()
    if not self.ProfessionButtons then return end
    local selected = self.SelectedProfessions or {}
    for id, entry in pairs(self.ProfessionButtons) do
        if selected[id] then
            entry.border:Show()
        else
            entry.border:Hide()
        end
    end
end

function Artisan.UI:BuildCategoryBar()
    if not self.CategoryBar or not self.FullList then return end

    for _, btn in ipairs(self.CategoryButtons or {}) do
        btn:Hide()
    end
    self.CategoryButtons = {}

    local seen = {}
    local groups = {}
    for _, row in ipairs(self.FullList) do
        local g = row.group or "Прочее"
        if not seen[g] then
            seen[g] = true
            tinsert(groups, g)
        end
    end
    table.sort(groups, function(a, b) return a < b end)

    local ALL = "Все"
    local labels = { ALL }
    for _, g in ipairs(groups) do labels[#labels + 1] = g end

    local bar = self.CategoryBar
    local pad = 8
    local maxX = math.max(100, bar:GetWidth() or 400)

    local x = 0
    local y = 0
    for _, label in ipairs(labels) do
        local btn = CreateFrame("Button", nil, bar)
        btn:SetPoint("TOPLEFT", bar, "TOPLEFT", x, -y)
        btn:SetHeight(18)

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("LEFT", btn, "LEFT", 2, 0)
        txt:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        txt:SetText(label)
        txt:SetJustifyH("LEFT")
        btn.txt = txt

        local active = (self.GroupFilter or ALL) == label
        if active then
            txt:SetTextColor(1, 0.82, 0)
        else
            txt:SetTextColor(0.7, 0.7, 0.7)
        end

        btn:SetScript("OnClick", function(self)
            local g
            if self.label == ALL then
                g = nil
            else
                g = self.label
            end
            Artisan.UI:SetGroup(g)
        end)
        btn.label = label

        local w = txt:GetStringWidth() + 8
        if w < 30 then w = 30 end
        if x + w + pad > maxX and x > 0 then
            x = 0
            y = y + CATEGORY_ROW_HEIGHT
        end

        -- Не рисуем за пределами зарезервированной области категорий,
        -- чтобы раскладка окна оставалась фиксированной.
        if y + CATEGORY_ROW_HEIGHT > CATEGORY_ROWS_MAX * CATEGORY_ROW_HEIGHT then
            btn:Hide()
        else
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", x, -y)
            btn:SetWidth(w)
            x = x + w + pad
            tinsert(self.CategoryButtons, btn)
        end
    end
end

function Artisan.UI:SetFilter(text)
    self.FilterText = text or ""
    self:RefreshList()
end

function Artisan.UI:ToggleSort(key)
    if self.SortKey == key then
        self.SortDir = self.SortDir == 1 and -1 or 1
    else
        self.SortKey = key
        self.SortDir = -1
    end
    self:RefreshList()
    self:RefreshColumnHeaders()
end

function Artisan.UI:RefreshList()
    if not self.FullList then return end

    local list = {}
    local filter = (self.FilterText or ""):lower()
    local group = self.GroupFilter
    for i = 1, #self.FullList do
        local row = self.FullList[i]
        if row then
            if group and (row.group or "Прочее") ~= group then
                -- skip: не из выбранной категории
            elseif filter ~= "" and not (row.itemName and row.itemName:lower():find(filter, 1, true)) then
                -- skip: не совпало с поиском
            else
                tinsert(list, row)
            end
        end
    end

    local key = self.SortKey or "profit"
    local dir = self.SortDir or -1
    table.sort(list, function(a, b)
        if key == "itemName" then
            local an, bn = a.itemName or "", b.itemName or ""
            if an == bn then return false end
            return dir == 1 and an < bn or an > bn
        end
        local av, bv = a[key] or 0, b[key] or 0
        if av == bv then return false end
        return dir == 1 and av < bv or av > bv
    end)

    self.CurrentList = list
    FauxScrollFrame_SetOffset(self.ScrollFrame, 0)
    self:UpdateScroll()
end

function Artisan.UI:RefreshColumnHeaders()
    if not self.ColumnHeaders then return end
    for _, btn in pairs(self.ColumnHeaders) do
        local col = btn.col
        if self.SortKey == col.sortKey then
            local arrow = self.SortDir == 1 and " ▲" or " ▼"
            btn.txt:SetText(col.text .. arrow)
            btn.txt:SetTextColor(1, 1, 1)
        else
            btn.txt:SetText(col.text)
            btn.txt:SetTextColor(0.7, 0.7, 0.7)
        end
    end
end

function Artisan.UI:UpdateScroll()
    if not self.CurrentList or not self.ScrollFrame then return end

    local totalItems = #self.CurrentList
    local maxOffset = math.max(0, totalItems - VISIBLE_ROWS)
    local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)
    if offset < 0 then offset = 0 end
    if offset > maxOffset then offset = maxOffset end
    FauxScrollFrame_SetOffset(self.ScrollFrame, offset)

    if self.ScrollBar then
        local scrollBar = self.ScrollBar
        if totalItems > VISIBLE_ROWS then
            scrollBar:Show()
            scrollBar:SetMinMaxValues(0, maxOffset)
            scrollBar:SetValueStep(1)
            scrollBar:SetValue(offset)
        else
            scrollBar:Hide()
        end
    end

    for i = 1, VISIBLE_ROWS do
        local index = offset + i
        local data = self.CurrentList[index]
        local row = self.RowFrames[i]

        if data then
            row:Show()

            row.icon:SetTexture(data.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(data.itemName or ("ID: " .. data.itemID))
            row.cost:SetText(Artisan.Utils:FormatMoney(data.cost))
            row.sell:SetText(Artisan.Utils:FormatMoney(data.sell))
            row.profit:SetText(Artisan.Utils:FormatMoney(data.profit))

            row.data = data
        else
            row:Hide()
        end
    end
end

function Artisan.UI:SearchOnAuctionHouse(itemName)
    if not itemName or itemName == "" then return end

    local ahOpen = (AuctionHouseFrame and AuctionHouseFrame:IsShown()) or (AuctionFrame and AuctionFrame:IsShown())
    if not ahOpen then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r Открой аукцион, чтобы искать предмет.")
        return
    end

    local box = _G["AuctionHouseFrameSearchBarSearchBox"]
        or _G["AuctionHouseFrameSearchBox"]
        or _G["AuctionFrameBrowseSearchBox"]
    if not box then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]|r Не найден поиск аукциона.")
        return
    end

    box:SetText(itemName)

    local ok, err = pcall(function()
        if AuctionHouseFrame and AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchButton then
            AuctionHouseFrame.SearchBar.SearchButton:Click()
        elseif _G["AuctionHouseFrameSearchButton"] then
            _G["AuctionHouseFrameSearchButton"]:Click()
        elseif AuctionFrameBrowse_Search then
            AuctionFrameBrowse_Search()
        end
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]|r Ошибка запуска поиска: " .. tostring(err))
    end
end