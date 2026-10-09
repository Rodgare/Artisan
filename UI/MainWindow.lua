local addonName, Artisan = ...

Artisan.UI = Artisan.UI or {}

Artisan.UI.KnownRecipes = Artisan.UI.KnownRecipes or {}
Artisan.UI.KnownRecipesByProf = Artisan.UI.KnownRecipesByProf or {}
Artisan.UI.KnownRecipesByChar = Artisan.UI.KnownRecipesByChar or {}

local LAYOUT = {
    frameWidth = 900, frameHeight = 600,
    minWidth = 360, maxWidth = 1200,
    minHeight = 360, maxHeight = 900,
    iconX = 4, iconSize = 18, nameX = 120, nameWidth = 90,
    colCostX = 195, colCostWidth = 100,
    colSellX = 250, colSellWidth = 100,
    colProfitX = 295, colProfitWidth = 110,
    colSkillX = 420, colSkillWidth = 90,
    btnCraftRightX = 750, btnReagentsRightX = 685,
    btnWidth = 60, btnReagentsWidth = 65, btnGap = 2,
}

-- Responsive layout config
local COL_W = { cost = 72, sell = 70, profit = 84, skill = 84 }
local COL_GAP = 10
local CTRL = { rightPad = 8, gap = 4, buyW = 62, craftW = 56, iconW = 23, iconGap = 2 }
local BREAKPOINTS = {
    { w = 900, cols = { "name", "cost", "sell", "profit", "skill" }, category = true,  reagents = true,  craft = true },
    { w = 760, cols = { "name", "cost", "sell", "profit" },          category = false, reagents = true,  craft = true },
    { w = 600, cols = { "name", "cost", "profit" },                  category = false, reagents = false, craft = false },
    { w = 0,   cols = { "name", "profit" },                          category = false, reagents = false, craft = false },
}
local function GetBreakpoint(W)
    for _, bp in ipairs(BREAKPOINTS) do
        if W >= bp.w then return bp end
    end
    return BREAKPOINTS[#BREAKPOINTS]
end
local COL_ORDER = { "cost", "sell", "profit", "skill" }

local ROW_HEIGHT = 21
local VISIBLE_ROWS = 21
local WHEEL_STEP = 5

local CATEGORY_ROWS_MAX = 6
local CATEGORY_ROW_HEIGHT = 15

local HEADER = {
    titleH = 15,
    profY = -24,
    searchY = -57,
    checkY = -78,
    headerY = -100,
    profSize = 27,
    profGap = 4,
    searchWidth = 306,
}

local CATEGORY_ORDER = {"Настойки", "Зелья", "Эликсиры", "Самоцветы", "Доспехи", "Оружие", "Улучшения",
    
}

local COLUMNS ={
    { key = "name",   text = "Рецепт",   x = LAYOUT.nameX, width = LAYOUT.nameWidth, align = "LEFT",  sortKey = "itemName" },
    { key = "cost",   text = "Затраты",  x = LAYOUT.colCostX, width = LAYOUT.colCostWidth, align = "RIGHT", sortKey = "cost" },
    { key = "sell",   text = "Продажа",  x = LAYOUT.colSellX, width = LAYOUT.colSellWidth, align = "RIGHT", sortKey = "sell" },
    { key = "profit", text = "Прибыль",  x = LAYOUT.colProfitX, width = LAYOUT.colProfitWidth, align = "RIGHT", sortKey = "profit" },
    { key = "skill",  text = "Навык",    x = LAYOUT.colSkillX, width = LAYOUT.colSkillWidth, align = "RIGHT", sortKey = "skill" },
}

local REAGENT_ICON_SIZE = 23
local REAGENT_ICON_GAP = 2
local MAX_REAGENT_ICONS = 5
local REAGENT_X = LAYOUT.reagentX

function Artisan.UI:GetCurrentCharKey()
    return UnitName("player") or ""
end

function Artisan.UI:InitKnownRecipesDB()
    ArtisanDB = ArtisanDB or {}
    ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}

    local normalized = {}
    local needRewrite = false
    for key, recipes in pairs(ArtisanDB.knownRecipes) do
        local charName = key:match("^([^%-]+)") or key
        if charName ~= key then needRewrite = true end
        normalized[charName] = normalized[charName] or {}
        for spellID in pairs(recipes) do
            normalized[charName][spellID] = true
        end
    end
    if needRewrite then
        ArtisanDB.knownRecipes = normalized
    end

    local name = UnitName("player")
    if not name or name == "" then
        Artisan.UI.CurrentCharKey = nil
        return
    end
    Artisan.UI.CurrentCharKey = name
    ArtisanDB.knownRecipes[name] = ArtisanDB.knownRecipes[name] or {}

    for spellID in pairs(ArtisanDB.knownRecipes[name]) do
        Artisan.UI.KnownRecipes[spellID] = true
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon ~= "Artisan" then
        return
    end
    Artisan.UI:InitKnownRecipesDB()
end)

function Artisan.UI:CreateMainWindow()
    if ArtisanMainFrame then return end

    local frame = CreateFrame("Frame", "ArtisanMainFrame", UIParent)
    tinsert(UISpecialFrames, "ArtisanMainFrame")
    frame:SetSize(LAYOUT.frameWidth, LAYOUT.frameHeight)
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
        Artisan.UI:ScanKnownRecipes()
        Artisan.UI:ApplyLayout()
    end)

    -- Отслеживаем ширину и применяем адаптивную раскладку при изменении
    frame:SetScript("OnUpdate", function(self)
        local w = self:GetWidth()
        local h = self:GetHeight()
        if w < LAYOUT.minWidth then w = LAYOUT.minWidth self:SetWidth(w) end
        if w > LAYOUT.maxWidth then w = LAYOUT.maxWidth self:SetWidth(w) end
        if h < LAYOUT.minHeight then h = LAYOUT.minHeight self:SetHeight(h) end
        if h > LAYOUT.maxHeight then h = LAYOUT.maxHeight self:SetHeight(h) end
        if w ~= Artisan.UI.LastWidth then
            Artisan.UI.LastWidth = w
            Artisan.UI:ApplyLayout()
        end
    end)

    -- Уголок для ресайза (правый нижний угол): короткая полоска у угла, длиннее по диагонали вверх-влево
    frame:SetResizable(true)
    local resizer = CreateFrame("Frame", nil, frame)
    resizer:SetSize(22, 22)
    resizer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizer:EnableMouse(true)
    resizer:RegisterForDrag("LeftButton")
    for i = 0, 2 do
        local line = resizer:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface/Buttons/WHITE8X8")
        line:SetVertexColor(1, 1, 1, 0.6)
        line:SetSize(4 + i * 5, 1)
        line:SetPoint("CENTER", resizer, "CENTER", 6 - i * 4, -6 + i * 4)
        line:SetRotation(0.78539816339)
    end

    resizer:SetScript("OnDragStart", function(self)
        self:GetParent():StartSizing("BOTTOMRIGHT")
    end)
    resizer:SetScript("OnDragStop", function(self)
        self:GetParent():StopMovingOrSizing()
    end)

    frame:Hide()

    Artisan.UI.MainFrame = frame

    self:CreateTopBar(frame)
    self:CreateRecipeList(frame)
    self:ApplyLayout()
end

-- Адаптивная раскладка: позиционирует столбцы, кнопки и панели по ширине контента.
function Artisan.UI:ApplyLayout()
    local scroll = self.ScrollFrame
    if not scroll then return end
    local W = self.MainFrame and self.MainFrame:GetWidth() or LAYOUT.frameWidth
    local rw = (scroll:GetWidth() or 0) - 18
    if rw <= 0 then rw = W - 20 end

    local bp = GetBreakpoint(W)
    local showCol = {}
    for _, k in ipairs(bp.cols) do showCol[k] = true end

    local PAD = 4
    local nameStartX = PAD + 18 + 6

    -- Правый блок управления: Купить + (Крафт) + (иконки реагентов)
    local craftShown = bp.craft
    local reagentShown = bp.reagents
    local blockW = CTRL.buyW + CTRL.gap
    if craftShown then blockW = blockW + CTRL.craftW + CTRL.gap end
    if reagentShown then blockW = blockW + CTRL.gap + MAX_REAGENT_ICONS * CTRL.iconW + (MAX_REAGENT_ICONS - 1) * CTRL.iconGap end
    local controlsLeft = (rw - CTRL.rightPad) - blockW

    -- Колонки слева, от name к числовым, с распределением свободного места
    local nums = {}
    for _, k in ipairs(COL_ORDER) do
        if showCol[k] then nums[#nums + 1] = k end
    end
    local n = #nums
    local numTotal = 0
    for _, k in ipairs(nums) do numTotal = numTotal + COL_W[k] end
    if n > 1 then numTotal = numTotal + (n - 1) * COL_GAP end

    local available = (controlsLeft - 8) - nameStartX
    local nameMin, nameCap = 80, 260
    local trailing = (n > 0) and COL_GAP or 0
    local free = available - (nameMin + numTotal + trailing)
    local nameW, gap = nameMin, COL_GAP
    if free > 0 then
        if free <= (nameCap - nameMin) then
            nameW = nameMin + free
        else
            nameW = nameCap
            gap = COL_GAP + (free - (nameCap - nameMin)) / math.max(1, n)
        end
    end

    local colX, colW = { name = nameStartX }, { name = nameW }
    local cx = nameStartX + nameW + gap
    for _, k in ipairs(nums) do
        colX[k] = cx
        colW[k] = COL_W[k]
        cx = cx + COL_W[k] + gap
    end

    -- Заголовки колонок
    for k, btn in pairs(self.ColumnHeaders or {}) do
        if showCol[k] and colX[k] then
            btn:Show()
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", self.HeaderFrame or btn:GetParent(), "LEFT", colX[k], 0)
            btn:SetSize(colW[k], 18)
        else
            btn:Hide()
        end
    end
    if self.ReagentHeader then
        self.ReagentHeader:ClearAllPoints()
        if reagentShown then
            self.ReagentHeader:Show()
            local zr = rw - CTRL.rightPad - CTRL.buyW - CTRL.gap
            if craftShown then zr = zr - CTRL.craftW - CTRL.gap end
            zr = zr - CTRL.gap - CTRL.iconGap
            self.ReagentHeader:SetPoint("RIGHT", self.HeaderFrame or self.ReagentHeader:GetParent(), "LEFT", zr, 0)
        else
            self.ReagentHeader:Hide()
        end
    end
    if self.CategoryBar then self.CategoryBar:SetShown(bp.category) end

    -- Поле поиска: на узком окне во всю ширину
    if self.FilterBox then
        self.FilterBox:ClearAllPoints()
        if W < 600 then
            self.FilterBox:SetPoint("TOPLEFT", self.MainFrame, "TOPLEFT", 10, HEADER.searchY)
            self.FilterBox:SetPoint("TOPRIGHT", self.MainFrame, "TOPRIGHT", -10, 0)
        else
            self.FilterBox:SetPoint("TOPLEFT", self.MainFrame, "TOPLEFT", 10, HEADER.searchY)
            self.FilterBox:SetSize(HEADER.searchWidth, 18)
        end
    end

    self.ShowReagentIcons = reagentShown

    for _, row in ipairs(self.RowFrames or {}) do
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", colX.name, 0)
        row.name:SetWidth(nameW)
        if row.nameBtn then
            row.nameBtn:ClearAllPoints()
            row.nameBtn:SetPoint("LEFT", row, "LEFT", colX.name - 2, 0)
            row.nameBtn:SetSize(nameW + 4, ROW_HEIGHT)
        end

        local function PlaceField(key, fs, btn)
            if showCol[key] then
                fs:Show()
                fs:ClearAllPoints()
                fs:SetPoint("LEFT", row, "LEFT", colX[key], 0)
                fs:SetWidth(colW[key])
                if btn then
                    btn:Show()
                    btn:ClearAllPoints()
                    btn:SetPoint("LEFT", row, "LEFT", colX[key] - 2, 0)
                    btn:SetSize(colW[key] + 4, ROW_HEIGHT)
                end
            else
                fs:Hide()
                if btn then btn:Hide() end
            end
        end
        PlaceField("cost", row.cost, row.costBtn)
        PlaceField("sell", row.sell, row.sellBtn)
        PlaceField("profit", row.profit, row.profitBtn)

        if showCol.skill then
            local sx = colX.skill + colW.skill
            row.skillGr:Show()
            row.skillGr:ClearAllPoints()
            row.skillGr:SetPoint("RIGHT", row, "LEFT", sx, 0)
            row.skillY:Show()
            row.skillG:Show()
            row.skillR:Show()
        else
            row.skillGr:Hide()
            row.skillY:Hide()
            row.skillG:Hide()
            row.skillR:Hide()
        end

        row.reagentsBtn.layoutAllowed = true
        row.reagentsBtn:ClearAllPoints()
        row.reagentsBtn:SetPoint("RIGHT", row, "RIGHT", -CTRL.rightPad, 0)

        if craftShown then
            row.craftBtn.layoutAllowed = true
            row.craftBtn:ClearAllPoints()
            row.craftBtn:SetPoint("RIGHT", row.reagentsBtn, "LEFT", -CTRL.gap, 0)
        else
            row.craftBtn.layoutAllowed = false
        end

        if reagentShown then
            local ref = craftShown and row.craftBtn or row.reagentsBtn
            for k = 1, MAX_REAGENT_ICONS do
                local ic = row.reagentIcons[k]
                if ic then
                    ic:ClearAllPoints()
                    ic:SetPoint("RIGHT", ref, "LEFT",
                        -(CTRL.gap + CTRL.iconGap + (k - 1) * (CTRL.iconW + CTRL.iconGap)), 0)
                end
            end
        end
    end
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
    -- Ряд 1: заголовок с именем аддона
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -4)
    title:SetText("Artisan")
    title:SetTextColor(1, 0.82, 0)
    self.WindowTitle = title

    -- Ряд 2 (слева): фильтр по профессиям
    local size = HEADER.profSize
    local gap = HEADER.profGap
    for idx, prof in ipairs(PROFESSIONS) do
        local btn = CreateFrame("Button", nil, parentFrame)
        btn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10 + (idx - 1) * (size + gap), HEADER.profY)
        btn:SetSize(size, size)

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
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -6, -6)

    local text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    text:SetText("X")
    text:SetTextColor(0.6, 0.6, 0.6)

    closeBtn:SetScript("OnEnter", function() text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() text:SetTextColor(0.6, 0.6, 0.6) end)
    closeBtn:SetScript("OnClick", function() parentFrame:Hide() end)

    -- Ряд 2 (справа): категории аукциона
    local categoryBar = CreateFrame("Frame", nil, parentFrame)
    categoryBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 340, HEADER.profY)
    categoryBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -40, -4)
    categoryBar:SetHeight(CATEGORY_ROWS_MAX * CATEGORY_ROW_HEIGHT)
    self.CategoryBar = categoryBar
end

function Artisan.UI:CreateRecipeList(parentFrame)
    local filterBox = CreateFrame("EditBox", nil, parentFrame, "InputBoxTemplate")
    filterBox:SetSize(HEADER.searchWidth, 18)
    filterBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, HEADER.searchY)
    filterBox:SetAutoFocus(false)
    filterBox:SetTextInsets(10, 18, 0, 0)
    self.FilterBox = filterBox

    local placeholder = filterBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholder:SetPoint("LEFT", filterBox, "LEFT", 7, 0)
    placeholder:SetText("Поиск")
    placeholder:SetTextColor(0.4, 0.4, 0.4)
    placeholder:SetJustifyH("LEFT")

    local clearBtn = CreateFrame("Button", nil, filterBox)
    clearBtn:SetSize(16, 16)
    clearBtn:SetPoint("RIGHT", filterBox, "RIGHT", -4, 0)
    clearBtn:Hide()
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearText:SetAllPoints(clearBtn)
    clearText:SetText("x")
    clearText:SetTextColor(0.6, 0.6, 0.6)
    clearBtn:SetScript("OnEnter", function() clearText:SetTextColor(1, 0.3, 0.3) end)
    clearBtn:SetScript("OnLeave", function() clearText:SetTextColor(0.6, 0.6, 0.6) end)
    clearBtn:SetScript("OnClick", function()
        filterBox:SetText("")
        filterBox:SetFocus()
    end)

    local function UpdateFilterBox()
        local text = filterBox:GetText()
        if text and text ~= "" then
            placeholder:Hide()
            clearBtn:Show()
        else
            if filterBox:HasFocus() then
                placeholder:Hide()
            else
                placeholder:Show()
            end
            clearBtn:Hide()
        end
    end

    filterBox:SetScript("OnTextChanged", function(self)
        Artisan.UI:SetFilter(self:GetText())
        UpdateFilterBox()
    end)
    filterBox:SetScript("OnEditFocusGained", UpdateFilterBox)
    filterBox:SetScript("OnEditFocusLost", UpdateFilterBox)
    UpdateFilterBox()

    local showBop = CreateFrame("CheckButton", "ArtisanShowBopCheck", parentFrame, "UICheckButtonTemplate")
    showBop:SetSize(20, 20)
    showBop:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, HEADER.checkY)
    showBop:SetChecked(false)
    local showBopLabel = _G["ArtisanShowBopCheckText"]
    if showBopLabel then
        showBopLabel:SetText("Личные (BoP)")
        showBopLabel:SetTextColor(0.7, 0.7, 0.7)
    end
    showBop:SetScript("OnClick", function(self)
        Artisan.UI:SetShowBOP(self:GetChecked())
    end)

    local showKnown = CreateFrame("CheckButton", "ArtisanShowKnownCheck", parentFrame, "UICheckButtonTemplate")
    showKnown:SetSize(20, 20)
    showKnown:SetPoint("LEFT", showBop, "RIGHT", 125, 0)
    showKnown:SetChecked(false)
    local showKnownLabel = _G["ArtisanShowKnownCheckText"]
    if showKnownLabel then
        showKnownLabel:SetText("Только изученные")
        showKnownLabel:SetTextColor(0.7, 0.7, 0.7)
    end
    showKnown:SetScript("OnClick", function(self)
        Artisan.UI:SetShowKnown(self:GetChecked())
    end)

    local header = CreateFrame("Frame", nil, parentFrame)
    header:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, HEADER.headerY)
    header:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, 0)
    header:SetHeight(18)
    self.HeaderFrame = header

    local scrollFrame = CreateFrame("ScrollFrame", "ArtisanRecipeScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 30)

    self.ColumnHeaders = {}
    for _, col in ipairs(COLUMNS) do
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(col.width, 18)
        btn:SetPoint("LEFT", header, "LEFT", col.x, 0)
        btn.col = col

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetAllPoints(btn)
        txt:SetText(col.text)
        txt:SetJustifyH(col.align)
        txt:SetTextColor(1, 1, 1)
        btn.txt = txt

        if col.sortKey then
            btn:SetScript("OnEnter", function(self)
                self.txt:SetTextColor(1, 1, 1)
            end)
            btn:SetScript("OnLeave", function()
                Artisan.UI:RefreshColumnHeaders()
            end)
            btn:SetScript("OnClick", function(self)
                Artisan.UI:ToggleSort(self.col.sortKey)
            end)
        else
            txt:SetTextColor(0.7, 0.7, 0.7)
        end

        self.ColumnHeaders[col.key] = btn
    end

    -- Заголовок колонки реагентов (выравнивается по правому краю иконок реагентов)
    local reagentHeader = CreateFrame("Button", nil, header)
    reagentHeader:SetSize(120, 18)
    local reagentRight = LAYOUT.btnReagentsWidth + LAYOUT.btnWidth + LAYOUT.btnGap + REAGENT_ICON_GAP + (LAYOUT.frameWidth - 20 - 750)
    reagentHeader:SetPoint("RIGHT", header, "RIGHT", -reagentRight, 0)
    local reagentTxt = reagentHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reagentTxt:SetAllPoints(reagentHeader)
    reagentTxt:SetText("Реагенты")
    reagentTxt:SetJustifyH("RIGHT")
    reagentTxt:SetTextColor(0.7, 0.7, 0.7)
    self.ReagentHeader = reagentHeader

    self.RowFrames = {}
    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, parentFrame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", scrollFrame, "RIGHT", -18, 0)

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
        row.name:SetWidth(220)
        row.name:SetJustifyH("LEFT")

        row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cost:SetPoint("LEFT", row, "LEFT", LAYOUT.colCostX, 0)
        row.cost:SetWidth(LAYOUT.colCostWidth)
        row.cost:SetJustifyH("RIGHT")

        row.sell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.sell:SetPoint("LEFT", row, "LEFT", LAYOUT.colSellX, 0)
        row.sell:SetWidth(LAYOUT.colSellWidth)
        row.sell:SetJustifyH("RIGHT")

        row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.profit:SetPoint("LEFT", row, "LEFT", LAYOUT.colProfitX, 0)
        row.profit:SetWidth(LAYOUT.colProfitWidth)
        row.profit:SetJustifyH("RIGHT")

        row.skillGr = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.skillGr:SetPoint("RIGHT", row, "LEFT", LAYOUT.colSkillX + LAYOUT.colSkillWidth, 0)
        row.skillGr:SetTextColor(0.6, 0.6, 0.6)

        row.skillG = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.skillG:SetPoint("RIGHT", row.skillGr, "LEFT", 0, 0)
        row.skillG:SetTextColor(0.2, 1, 0.2)

        row.skillY = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.skillY:SetPoint("RIGHT", row.skillG, "LEFT", 0, 0)
        row.skillY:SetTextColor(1, 1, 0)

        row.skillR = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.skillR:SetPoint("RIGHT", row.skillY, "LEFT", 0, 0)
        row.skillR:SetTextColor(1, 0.3, 0.3)

        local function CreateStyledButton(parent, text, width, onClick)
            local btn = CreateFrame("Button", nil, parent)
            btn:SetSize(width, 20)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture("Interface/Buttons/WHITE8X8")
            bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
            btn.bg = bg

            local border = btn:CreateTexture(nil, "BORDER")
            border:SetAllPoints()
            border:SetTexture("Interface/Buttons/WHITE8X8")
            border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
            btn.border = border

            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("CENTER")
            txt:SetText(text)
            txt:SetTextColor(1, 0.82, 0)
            btn.txt = txt

            btn:SetScript("OnClick", onClick)
            btn:EnableMouse(true)
            btn:SetScript("OnEnter", function(self)
                if not self:IsEnabled() then return end
                self.bg:SetVertexColor(0.35, 0.35, 0.5, 1)
                self.border:SetVertexColor(0.9, 0.75, 0.3, 1)
                self.txt:SetTextColor(1, 1, 1)
            end)
            btn:SetScript("OnLeave", function(self)
                if self:IsEnabled() then
                    self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                    self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                    self.txt:SetTextColor(1, 0.82, 0)
                else
                    self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                    self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                    self.txt:SetTextColor(0.5, 0.45, 0.35)
                end
            end)
            btn:SetScript("OnUpdate", function(self)
                if self:IsMouseOver() then
                    if self:IsEnabled() then
                        self.bg:SetVertexColor(0.35, 0.35, 0.5, 1)
                        self.border:SetVertexColor(0.9, 0.75, 0.3, 1)
                        self.txt:SetTextColor(1, 1, 1)
                    else
                        -- Disabled: muted, no hover effect
                        self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                        self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                        self.txt:SetTextColor(0.5, 0.45, 0.35)
                    end
                else
                    if self:IsEnabled() then
                        self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                        self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                        self.txt:SetTextColor(1, 0.82, 0)
                    else
                        -- Disabled: muted, no hover effect
                        self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                        self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                        self.txt:SetTextColor(0.5, 0.45, 0.35)
                    end
                end
            end)

            btn.SetEnabledCustom = function(self, enabled)
                self.customEnabled = enabled == true
                if self.customEnabled then
                    self:Enable()
                    self:SetAlpha(1)
                    self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                    self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                    self.txt:SetTextColor(1, 0.82, 0)
                    self.txt:SetText("Крафт")
                else
                    self:Enable()
                    self:SetAlpha(0.35)
                    self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                    self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                    self.txt:SetTextColor(0.5, 0.45, 0.35)
                end
            end

            return btn
        end

        row.craftBtn = CreateStyledButton(row, "Крафт", 60, function(self, button)
            if not self.customEnabled then return end
            if not row.data or not row.data.spellID then return end
            if button == "LeftButton" then
                Artisan.UI:OpenCraftWindow(row.data.spellID, row.data.profID, row.data.itemID)
            end
        end)

        row.reagentsBtn = CreateStyledButton(row, "Купить", 65, function(self)
            if row.data and row.data.reagents then
                Artisan.UI:SearchReagentsOnAH(row.data.reagents)
            end
        end)

        row.reagentsBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.craftBtn:SetPoint("RIGHT", row.reagentsBtn, "LEFT", -2, 0)

        row.craftBtn:Hide()
        row.reagentsBtn:Hide()
        row.reagentsBtn:SetScript("OnEnter", function(self)
            -- Mouseover visual
            if self:IsEnabled() then
                self.bg:SetVertexColor(0.35, 0.35, 0.5, 1)
                self.border:SetVertexColor(0.9, 0.75, 0.3, 1)
                self.txt:SetTextColor(1, 1, 1)
            end
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Поиск реагентов на АХ", 1, 1, 1)
            GameTooltip:Show()
        end)
        row.reagentsBtn:SetScript("OnLeave", function(self)
            -- Restore visual
            if self:IsEnabled() then
                self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                self.txt:SetTextColor(1, 0.82, 0)
            else
                self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                self.txt:SetTextColor(0.5, 0.45, 0.35)
            end
            GameTooltip:Hide()
        end)

        row.craftBtn:SetScript("OnEnter", function(self)
            -- Mouseover visual
            if self.customEnabled then
                self.bg:SetVertexColor(0.35, 0.35, 0.5, 1)
                self.border:SetVertexColor(0.9, 0.75, 0.3, 1)
                self.txt:SetTextColor(1, 1, 1)
            end
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.customEnabled then
                GameTooltip:SetText("Открыть окно профессии и выбрать рецепт", 1, 1, 1)
            else
                GameTooltip:SetText("Рецепт не изучен", 0.7, 0.7, 0.7)
                if row.data.spellID then
                    Artisan.UI:AddRecipeSourcesTooltip(row.data.spellID)
                end
                local chars = Artisan.UI:GetKnownChars(row.data.spellID)
                if #chars > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Изучено на:", 1, 1, 0)
                    for _, char in ipairs(chars) do
                        local isCurrent = (char == Artisan.UI.CurrentCharKey)
                        if isCurrent then
                            GameTooltip:AddLine("  |cff00ff00" .. char .. "|r", 1, 1, 1)
                        else
                            GameTooltip:AddLine("  " .. char, 0.7, 0.7, 0.7)
                        end
                    end
                end
            end

            GameTooltip:Show()
        end)
        row.craftBtn:SetScript("OnLeave", function(self)
            -- Restore visual
            if self.customEnabled then
                self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                self.txt:SetTextColor(1, 0.82, 0)
            else
                self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                self.txt:SetTextColor(0.5, 0.45, 0.35)
            end
            GameTooltip:Hide()
        end)

        self.RowFrames[i] = row
    end

    Artisan.UI.CurrentCharKey = Artisan.UI:GetCurrentCharKey()

    function Artisan.UI:ScanKnownRecipes()
        if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return end
        local numSkills = GetNumTradeSkills()
        if numSkills == 0 then return end

        local profName = GetTradeSkillLine()
        Artisan.UI.KnownRecipesByProf[profName] = Artisan.UI.KnownRecipesByProf[profName] or {}
        Artisan.UI.KnownRecipesByChar[Artisan.UI.CurrentCharKey] = Artisan.UI.KnownRecipesByChar[Artisan.UI.CurrentCharKey] or {}

        local newRecipes = {}
        for i = 1, numSkills do
            local skillName, skillType = GetTradeSkillInfo(i)
            if skillType ~= "header" and skillName then
                local link = GetTradeSkillRecipeLink(i)
                local spellID = nil
                if link then
                    spellID = tonumber(link:match("Henchant:(%d+)"))
                    if not spellID then
                        local itemID = tonumber(link:match("Hitem:(%d+)"))
                        if itemID then
                            spellID = Artisan.UI:GetSpellIDByItemID(itemID)
                        end
                    end
                end
                if spellID then
                    Artisan.UI.KnownRecipes[spellID] = true
                    Artisan.UI.KnownRecipesByProf[profName][spellID] = true
                    Artisan.UI.KnownRecipesByChar[Artisan.UI.CurrentCharKey][spellID] = true
                    newRecipes[spellID] = true
                end
            end
        end

        if next(newRecipes) then
            ArtisanDB = ArtisanDB or {}
            ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}
            ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] = ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] or {}
            for spellID in pairs(newRecipes) do
                ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey][spellID] = true
            end
        end
    end

    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:SetScript("OnEvent", function()
        -- SavedVariables are auto-saved, but ensure table exists
        ArtisanDB = ArtisanDB or {}
        ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}
    end)

    local scanFrame = CreateFrame("Frame")
    scanFrame:RegisterEvent("TRADE_SKILL_SHOW")
    scanFrame:RegisterEvent("TRADE_SKILL_UPDATE")
    scanFrame:SetScript("OnEvent", function()
        Artisan.UI:ScanKnownRecipes()
        if Artisan.UI.MainFrame and Artisan.UI.MainFrame:IsShown() then
            Artisan.UI:UpdateScroll()
        end
    end)

    function Artisan.UI:IsRecipeKnown(spellID)
        return Artisan.UI.KnownRecipes[spellID] == true
    end

    -- Добавляет в тултип компактную подсказку, как получить рецепт.
    function Artisan.UI:AddRecipeSourcesTooltip(spellID)
        if not Artisan.RecipeSources then return end
        local data = Artisan.RecipeSources[spellID]
        if not data or not data.hint or data.hint == "" then return end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Как получить:", 1, 0.82, 0)
        GameTooltip:AddLine("  " .. data.hint, 1, 1, 1)
    end

    function Artisan.UI:GetKnownChars(spellID)
        local chars = {}
        ArtisanDB = ArtisanDB or {}
        if ArtisanDB.knownRecipes then
            for char, recipes in pairs(ArtisanDB.knownRecipes) do
                if recipes[spellID] then
                    tinsert(chars, char)
                end
            end
        end
        return chars
    end

    for i = 1, VISIBLE_ROWS do
        local row = self.RowFrames[i]
        local nameButton = CreateFrame("Button", nil, row)
        row.nameBtn = nameButton
        nameButton:SetSize(200, ROW_HEIGHT)
        nameButton:SetPoint("LEFT", row, "LEFT", 28, 0)
        nameButton:SetScript("OnEnter", function(self)
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. row.data.itemID)
            local inBags = GetItemCount(row.data.itemID) or 0
            GameTooltip:AddLine("В сумке: " .. inBags, 1, 1, 1)
            GameTooltip:Show()
        end)
        nameButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        nameButton:SetScript("OnClick", function(self, button)
            if button == "LeftButton" and row.data then
                Artisan.UI:SearchOnAuctionHouse(row.data.itemName)
            end
        end)

        local costButton = CreateFrame("Button", nil, row)
        row.costBtn = costButton
        costButton:SetSize(120, ROW_HEIGHT)
        costButton:SetPoint("LEFT", row, "LEFT", LAYOUT.colCostX, 0)
        costButton:SetScript("OnEnter", function(self)
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Затраты на крафт", 1, 0.82, 0)
            local reagents = row.data.reagents
            if reagents then
                for _, rg in ipairs(reagents) do
                    local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(rg.itemID)
                    local price = Artisan.Auctionator and Artisan.Auctionator:GetItemPrice(rg.itemID) or nil
                    local countInBags = GetItemCount(rg.itemID) or 0
                    local iconStr = itemTexture and ("|T" .. itemTexture .. ":16:16:0:0|t") or "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16|t"
                    local priceStr = price and (Artisan.Utils:FormatMoney(price) .. "/шт") or "—"
                    local qtyStr = (countInBags > 0) and (" (есть " .. countInBags .. ")") or " (нет в сумках)"
                    GameTooltip:AddLine(iconStr .. "  " .. (itemLink or (itemName or ("ID: " .. rg.itemID))) .. "  x" .. rg.count .. "  " .. priceStr .. qtyStr, 1, 1, 1)
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Итого: " .. Artisan.Utils:FormatMoney(row.data.cost), 1, 1, 1)
            GameTooltip:Show()
        end)
        costButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local sellButton = CreateFrame("Button", nil, row)
        row.sellBtn = sellButton
        sellButton:SetSize(100, ROW_HEIGHT)
        sellButton:SetPoint("LEFT", row, "LEFT", LAYOUT.colSellX, 0)
        sellButton:SetScript("OnEnter", function(self)
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Продажа", 1, 1, 1)
            local price = Artisan.Auctionator and Artisan.Auctionator:GetItemPrice(row.data.itemID) or nil
            if price then
                GameTooltip:AddLine("Последняя цена на АХ: " .. Artisan.Utils:FormatMoney(price), 1, 1, 1)
                if row.data.craftCount and row.data.craftCount > 1 then
                    GameTooltip:AddLine("За крафт (x" .. row.data.craftCount .. "): " .. Artisan.Utils:FormatMoney(row.data.sell), 0.7, 0.7, 0.7)
                end
            else
                GameTooltip:AddLine("Нет данных об аукционе", 0.7, 0.7, 0.7)
            end
            local rec = Artisan.UI:GetSalesForItem(row.data.itemID)
            if rec then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Продано: " .. (rec.qty or 0) .. " шт", 1, 0.82, 0)
                GameTooltip:AddLine("Выручка: " .. Artisan.Utils:FormatMoney(rec.revenue or 0), 1, 0.82, 0)
                GameTooltip:AddLine("Сделок: " .. (rec.count or 0), 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        sellButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local profitButton = CreateFrame("Button", nil, row)
        row.profitBtn = profitButton
        profitButton:SetSize(110, ROW_HEIGHT)
        profitButton:SetPoint("LEFT", row, "LEFT", LAYOUT.colProfitX, 0)
        profitButton:SetScript("OnEnter", function(self)
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Прибыль", 1, 1, 1)
            local rec = Artisan.UI:GetSalesForItem(row.data.itemID)
            if rec and (rec.profit or 0) ~= 0 then
                GameTooltip:AddLine("Прибыль за всё время: " .. Artisan.Utils:FormatMoney(rec.profit or 0), 1, 0.82, 0)
                GameTooltip:AddLine("Продано: " .. (rec.qty or 0) .. " шт", 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine("Нет сохранённых продаж", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("Прибыль за крафт: " .. Artisan.Utils:FormatMoney(row.data.profit), 1, 0.82, 0)
            end
            GameTooltip:Show()
        end)
        profitButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Иконки реагентов (количество в сумке / нужно; серые, если не хватает)
        row.reagentIcons = {}
        local btnBlock = LAYOUT.btnReagentsWidth + LAYOUT.btnWidth + LAYOUT.btnGap
        for k = 1, MAX_REAGENT_ICONS do
            local icon = CreateFrame("Button", nil, row)
            icon:SetSize(REAGENT_ICON_SIZE, REAGENT_ICON_SIZE)
            icon:SetPoint("RIGHT", row, "RIGHT", -(btnBlock + REAGENT_ICON_GAP + (k - 1) * (REAGENT_ICON_SIZE + REAGENT_ICON_GAP)), 0)
            icon:Hide()

            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints(icon)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon.tex = tex

            local countText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            countText:SetAllPoints(icon)
            countText:SetJustifyH("LEFT")
            countText:SetJustifyV("TOP")
            local fontName = countText:GetFont()
            countText:SetFont(fontName, 11, "OUTLINE")
            countText:SetTextColor(1, 1, 1)
            icon.countText = countText

            icon:SetScript("OnEnter", function(self)
                if not self.data then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. self.data.itemID)
                local have = GetItemCount(self.data.itemID) or 0
                if have < self.data.count then
                    GameTooltip:AddLine("В сумке: " .. have .. " / нужно " .. self.data.count .. " (не хватает " .. (self.data.count - have) .. ")", 1, 1, 1)
                else
                    GameTooltip:AddLine("В сумке: " .. have .. " / нужно " .. self.data.count, 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            icon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            icon:SetScript("OnClick", function(self, button)
                if button == "LeftButton"and self.data and self.data.name then
                    Artisan.UI:SearchOnAuctionHouse(self.data.name)
                end
            end)

            tinsert(row.reagentIcons, icon)
        end
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

    Artisan.UI:RegisterSalesTracking()
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
    local showBop = self.ShowBOP
    local showKnown = self.ShowKnown
    local function RowVisible(row)
        if row.bop and not showBop then return false end
        if showKnown and row.spellID and not Artisan.UI:IsRecipeKnown(row.spellID) then return false end
        return true
    end
    for _, row in ipairs(self.FullList) do
        local g = row.group or "Прочее"
        if RowVisible(row) and not seen[g] then
            seen[g] = true
            tinsert(groups, g)
        end
    end
    local orderIdx = {}
    for i, g in ipairs(CATEGORY_ORDER) do orderIdx[g] = i end
    table.sort(groups, function(a, b)
        local ia = orderIdx[a] or math.huge
        local ib = orderIdx[b] or math.huge
        if ia ~= ib then return ia < ib end
        return a < b
    end)

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

function Artisan.UI:SetShowBOP(show)
    self.ShowBOP = show and true or false
    self:RefreshList()
    self:BuildCategoryBar()
    if self.GroupFilter then
        self:RefreshList()
    end
end

function Artisan.UI:SetShowKnown(show)
    self.ShowKnown = show and true or false
    self:RefreshList()
    self:BuildCategoryBar()
    if self.GroupFilter then
        self:RefreshList()
    end
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
    local showBop = self.ShowBOP
    local showKnown = self.ShowKnown
    for i = 1, #self.FullList do
        local row = self.FullList[i]
        if row then
            if row.bop and not showBop then
            elseif group and (row.group or "Прочее") ~= group then
                -- skip: не из выбранной категории
            elseif filter ~= "" and not (row.itemName and row.itemName:lower():find(filter, 1, true)) then
                -- skip: не совпало с поиском
            elseif showKnown and row.spellID and not Artisan.UI:IsRecipeKnown(row.spellID) then
                -- skip: не изучен
            else
                tinsert(list, row)
            end
        end
    end

    local key = self.SortKey or "profit"
    local dir = self.SortDir or -1
    table.sort(list, function(a, b)
        if not a or not b then return false end
        local av, bv
        if key == "itemName" then
            av = a.itemName or ""
            bv = b.itemName or ""
        else
            av = a[key] or 0
            bv = b[key] or 0
        end
        if av == bv then return false end
        if dir == 1 then
            return av < bv
        else
            return av > bv
        end
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
            btn.txt:SetText(col.text)
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
            row.name:SetText((data.itemName or ("ID: " .. data.itemID)) .. " [" .. (data.itemID or "?") .. "]")
            row.cost:SetText(Artisan.Utils:FormatMoney(data.cost))
            row.sell:SetText(Artisan.Utils:FormatMoney(data.sell))
            row.profit:SetText(Artisan.Utils:FormatMoney(data.profit))
            if data.skillText and data.skillText ~= "" then
                local r, y, g, gr = strsplit("/", data.skillText)
                row.skillR:SetText(r or "")
                row.skillY:SetText(y and ("/" .. y) or "")
                row.skillG:SetText(g and ("/" .. g) or "")
                row.skillGr:SetText(gr and ("/" .. gr) or "")
            else
                row.skillR:SetText("")
                row.skillY:SetText("")
                row.skillG:SetText("")
                row.skillGr:SetText("")
            end

            row.data = data

            -- Craft button
            local craftBtn = row.craftBtn
            local reagentsBtn = row.reagentsBtn
            if data.spellID and craftBtn.layoutAllowed then
                local known = Artisan.UI:IsRecipeKnown(data.spellID)
                craftBtn:Show()
                if known then
                    craftBtn:SetEnabledCustom(true)
                    craftBtn.spellID = data.spellID
                    craftBtn.profID = data.profID
                else
                    craftBtn:SetEnabledCustom(false)
                    craftBtn.spellID = nil
                    craftBtn.profID = nil
                end
            else
                craftBtn:Hide()
                craftBtn:SetEnabledCustom(false)
                craftBtn.spellID = nil
                craftBtn.profID = nil
            end

            -- Reagents button
            if data.reagents and #data.reagents > 0 then
                reagentsBtn:Show()
            else
                reagentsBtn:Hide()
            end

            -- Reagent icons (сумка/нужно, серые если не хватает)
            local icons = row.reagentIcons
            if icons and self.ShowReagentIcons then
                for k = 1, MAX_REAGENT_ICONS do icons[k]:Hide() end
                if data.reagents and #data.reagents > 0 then
                    for k = 1, math.min(#data.reagents, MAX_REAGENT_ICONS) do
                        local rg = data.reagents[k]
                        local icon = icons[k]
                        local have = GetItemCount(rg.itemID) or 0
                        local need = rg.count or 0
                        local ok = have >= need
                        icon.tex:SetTexture(rg.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                        if ok then
                            icon.tex:SetDesaturated(false)
                            icon.tex:SetVertexColor(1, 1, 1, 1)
                        else
                            icon.tex:SetDesaturated(false)
                            icon.tex:SetVertexColor(0.62, 0.62, 0.62, 0.85)
                        end
                        icon.data = rg
                        icon.countText:SetText(have .. "/" .. need)
                        if ok then
                            icon.countText:SetTextColor(1, 1, 1)
                        else
                            icon.countText:SetTextColor(1, 0.5, 0.5)
                        end
                        icon:Show()
                    end
                end
            end
        else
            row:Hide()
            row.craftBtn:Hide()
            row.reagentsBtn:Hide()
        end
    end
end

function Artisan.UI:GetSpellIDByItemID(itemID)
    if not itemID then return nil end
    if not Artisan.UI.ReverseIndex then
        local idx = {}
        for profID, recipes in pairs(Artisan.RecipeDB or {}) do
            for spellID, data in pairs(recipes) do
                if data.itemID then
                    idx[data.itemID] = spellID
                end
            end
        end
        Artisan.UI.ReverseIndex = idx
    end
    return Artisan.UI.ReverseIndex[itemID]
end

function Artisan.UI:FindRecipeIndex(itemID, spellID)
    local num = GetNumTradeSkills()
    if num == 0 then return nil end
    for i = 1, num do
        local link = GetTradeSkillRecipeLink(i)
        if link then
            local id = tonumber(link:match("Hitem:(%d+)"))
            if id and itemID and id == itemID then return i end
            local sID = tonumber(link:match("Henchant:(%d+)"))
            if sID and spellID and sID == spellID then return i end
        end
    end
    return nil
end

function Artisan.UI:DumpTradeSkillFrame()
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Открой окно профессии сначала!")
        return
    end

    local lines = {}
    local count = 0
    local maxNodes = 160

    local function nodeInfo(child, depth)
        count = count + 1
        if count > maxNodes then return end
        local name = child:GetName() or "?"
        local objType = child:GetObjectType()
        local vis = child:IsVisible() and "V" or "H"
        local info = { string.rep("  ", depth) .. "[" .. count .. "] " .. vis .. " " .. name .. " <" .. objType .. ">" }

        if objType == "Button" then
            local fs = child:GetFontString()
            local txt = fs and fs:GetText() or ""
            info[#info + 1] = " txt='" .. txt .. "'"
            info[#info + 1] = child:IsEnabled() and "" or " DISABLED"
        elseif objType == "EditBox" then
            info[#info + 1] = " val='" .. (child:GetText() or "") .. "'"
        elseif objType == "CheckButton" then
            local fs = child:GetFontString()
            local txt = fs and fs:GetText() or ""
            info[#info + 1] = " checked=" .. tostring(child:GetChecked()) .. " txt='" .. txt .. "'"
        elseif objType == "Slider" then
            info[#info + 1] = " val=" .. tostring(child:GetValue())
        elseif objType == "FontString" then
            local txt = child:GetText() or ""
            if txt ~= "" then
                info[#info + 1] = " txt='" .. txt .. "'"
            end
        end

        table.insert(lines, table.concat(info, ""))
    end

    local function walk(parent, depth)
        if depth > 7 then return end
        local numChildren = parent:GetNumChildren()
        for i = 1, numChildren do
            if count > maxNodes then break end
            local child = select(i, parent:GetChildren())
            if child then
                nodeInfo(child, depth)
                walk(child, depth + 1)
            end
        end
    end

    nodeInfo(TradeSkillFrame, 0)
    walk(TradeSkillFrame, 1)

    local sel = GetTradeSkillSelectionIndex()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r === ДАМП TradeSkillFrame (" .. count .. " узлов) selection=" .. tostring(sel) .. " ===")
    for _, line in ipairs(lines) do
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r " .. line)
    end

    local keywords = { "оздат", "reate", "рафт", "колич", "создать", "всё", "all", "x", "Craft", "Create" }
    local founded = {}
    local function targetWalk(parent)
        for i = 1, parent:GetNumChildren() do
            local child = select(i, parent:GetChildren())
            if child then
                local objType = child:GetObjectType()
                local name = child:GetName() or "?"
                local txt = ""
                if objType == "FontString" then
                    txt = child:GetText() or ""
                elseif child.GetFontString then
                    local fs = child:GetFontString()
                    txt = fs and fs:GetText() or ""
                end
                local match = (objType == "EditBox") or (objType == "Slider")
                if txt ~= "" then
                    for _, kw in ipairs(keywords) do
                        if txt:find(kw, 1, true) then
                            match = true
                            break
                        end
                    end
                end
                if not match and name ~= "?" then
                    for _, kw in ipairs(keywords) do
                        if name:find(kw, 1, true) then
                            match = true
                            break
                        end
                    end
                end
                if match and #founded < 40 then
                    local vis = child:IsVisible() and "V" or "H"
                    local extra = ""
                    if objType == "EditBox" then
                        extra = " val='" .. (child:GetText() or "") .. "'"
                    elseif objType == "Slider" then
                        extra = " val=" .. tostring(child:GetValue())
                    elseif child.GetChecked then
                        extra = " checked=" .. tostring(child:GetChecked())
                    end
                    local enabled = child.IsEnabled and child:IsEnabled()
                    table.insert(founded, string.format("%s [%s] %s %s txt='%s'%s",
                        vis, objType, name, enabled and "" or "DISABLED", txt, extra))
                end
                targetWalk(child)
            end
        end
    end
    targetWalk(TradeSkillFrame)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r === ЦЕЛЕВЫЕ УЗЛЫ (" .. #founded .. ") ===")
    for _, line in ipairs(founded) do
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8844[Artisan]|r " .. line)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r === КОНЕЦ ДАМПА ===")

    ArtisanDebugDB = ArtisanDebugDB or {}
    ArtisanDebugDB.dump = lines
    ArtisanDebugDB.founded = founded
    ArtisanDebugDB.selection = sel
    ArtisanDebugDB.updated = time()
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r Дамп сохранён в ArtisanDebugDB (файл SavedVariables\\Artisan.lua на диске).")
end

function Artisan.UI:GetCreateButton()
    local candidates = {
        "TradeSkillFrameCreateButton",
        "TradeSkillCreateButton",
        "TradeSkillFrame_CreateButton",
        "TradeSkillFrameCreate",
        "CreateButton",
    }
    for _, name in ipairs(candidates) do
        local btn = _G[name]
        if btn and btn:GetObjectType() == "Button" then
            return btn
        end
    end

    if not TradeSkillFrame then return nil end

    local function scan(parent, depth)
        if depth > 8 then return nil end
        for i = 1, parent:GetNumChildren() do
            local child = select(i, parent:GetChildren())
            if child then
                if child:GetObjectType() == "Button" and child:IsVisible() then
                    local fs = child:GetFontString()
                    local text = fs and fs:GetText() or ""
                    if text:find("оздат", 1, true) or text:find("reate", 1, true) or text:find("рафт", 1, true) then
                        return child
                    end
                end
                local found = scan(child, depth + 1)
                if found then return found end
            end
        end
        return nil
    end

    return scan(TradeSkillFrame, 0)
end

function Artisan.UI:DebugDumpButtons()
    if not TradeSkillFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r TradeSkillFrame не существует")
        return
    end
    local count = 0
    local function walk(parent, depth)
        if count >= 20 or depth > 4 then return end
        for i = 1, parent:GetNumChildren() do
            if count >= 20 then return end
            local child = select(i, parent:GetChildren())
            if child then
                count = count + 1
                if child:GetObjectType() == "Button" then
                    local fs = child:GetFontString()
                    local text = fs and fs:GetText() or ""
                    local shown = child:IsVisible() and "shown" or "hidden"
                    DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r btn: " .. (child:GetName() or "?") .. " t='" .. text .. "' " .. shown)
                end
                walk(child, depth + 1)
            end
        end
    end
    walk(TradeSkillFrame, 0)
end

function Artisan.UI:OpenCraftWindow(spellID, profID, itemID)
    if not spellID then return end

    local profSpell = Artisan.UI:GetProfessionSpell(profID)
    if not profSpell then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Неизвестная профессия: " .. tostring(profID))
        return
    end

    if InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Нельзя открыть профессию в бою.")
        return
    end

    CastSpellByName(profSpell)

    local waitFrame = CreateFrame("Frame")
    local elapsed = 0
    waitFrame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed > 2 then
            self:SetScript("OnUpdate", nil)
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Окно профессии не открылось.")
            return
        end
        if TradeSkillFrame and TradeSkillFrame:IsShown() then
            self:SetScript("OnUpdate", nil)
            local idx = Artisan.UI:FindRecipeIndex(itemID, spellID)
            if idx then
                TradeSkillFrame_SetSelection(idx)
                TradeSkillFrame_Update()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Рецепт не найден в окне профессии.")
            end
        end
    end)
end

function Artisan.UI:CountReagentsForSelection(sel)
    sel = sel or GetTradeSkillSelectionIndex()
    if not sel or sel == 0 then return 0 end
    local num = 0
    if GetTradeSkillNumReagents then
        num = GetTradeSkillNumReagents(sel) or 0
    end
    local total = 0
    for i = 1, num do
        if GetTradeSkillReagentItemLink then
            local link = GetTradeSkillReagentItemLink(sel, i)
            if link then
                local itemID = tonumber(link:match("item:(%d+)"))
                if itemID then
                    total = total + (GetItemCount(itemID) or 0)
                end
            end
        end
    end
    return total
end

function Artisan.UI:TestCraft(count)
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Открой окно профессии и выбери рецепт, затем /arttestcraft N")
        return
    end
    local sel = GetTradeSkillSelectionIndex()
    if not sel or sel == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Выбери рецепт в окне профессии.")
        return
    end
    local name = select(1, GetTradeSkillInfo(sel))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff8844[Artisan]:|r === TEST craft: idx=%d name='%s' count=%d ===", sel, tostring(name), count))

    local function awaitThen(seconds, callback)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, e)
            t = t + e
            if t >= seconds then
                self:SetScript("OnUpdate", nil)
                callback()
            end
        end)
    end

    local methods = {}

    if CastSpellByName then
        table.insert(methods, {
            label = "CastSpellByName('" .. tostring(name) .. "')",
            run = function() pcall(CastSpellByName, name) end
        })
    end
    if CastSpellByID then
        local input = _G["TradeSkillInputBox"]
        table.insert(methods, {
            label = "CastSpellByID+InputBox",
            run = function()
                if input then
                    input:SetText(tostring(count))
                    local h = input:GetScript("OnTextChanged")
                    if h then pcall(h, input, true) end
                end
                local sID = select(3, GetTradeSkillInfo(sel))
                if sID then pcall(CastSpellByID, sID) end
            end
        })
    end
    local createBtn = Artisan.UI:GetCreateButton()
    local createAllBtn = _G["TradeSkillCreateAllButton"]
    if createBtn then
        table.insert(methods, {
            label = "Click 'Создать' (TradeSkillCreateButton)",
            run = function() pcall(createBtn.Click, createBtn) end
        })
    end
    if createAllBtn then
        table.insert(methods, {
            label = "Click 'Создать все' (TradeSkillCreateAllButton)",
            run = function() pcall(createAllBtn.Click, createAllBtn) end
        })
    end

    local i = 1
    local function nextMethod()
        if i > #methods then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r === TEST завершён: ни один метод не сработал ===")
            return
        end
        local m = methods[i]
        local before = Artisan.UI:CountReagentsForSelection(sel)
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8844[Artisan]:|r Метод: " .. m.label)
        pcall(m.run)
        awaitThen(2, function()
            local after = Artisan.UI:CountReagentsForSelection(sel)
            if after < before then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Artisan]:|r   СРАБОТАЛО: %d -> %d", before, after))
                return
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Artisan]:|r   нет эффекта: %d -> %d", before, after))
            i = i + 1
            nextMethod()
        end)
    end
    nextMethod()
end

function Artisan.UI:GetItemIDBySpellID(spellID)
    for profID, recipes in pairs(Artisan.RecipeDB or {}) do
        local data = recipes[spellID]
        if data and data.itemID then
            return data.itemID
        end
    end
    return nil
end

function Artisan.UI:GetProfessionSpell(profID)
    local spells = {
        Alchemy = "Алхимия",
        Blacksmithing = "Кузнечное дело",
        Enchanting = "Наложение чар",
        Engineering = "Инженерное дело",
        Inscription = "Начертание",
        Jewelcrafting = "Ювелирное дело",
        Leatherworking = "Кожевничество",
        Tailoring = "Портняжное дело",
        Cooking = "Кулинария",
        Smelting = "Горное дело",
    }
    return spells[profID]
end

function Artisan.UI:SearchReagentsOnAH(reagents)
    if not reagents or #reagents == 0 then return end

    local ahOpen = (AuctionHouseFrame and AuctionHouseFrame:IsShown()) or (AuctionFrame and AuctionFrame:IsShown())
    if not ahOpen then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[Artisan]|r Открой аукцион, чтобы искать реагенты.")
        return
    end

    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.MultiSearch then
        local searchTerms = {}
        for _, reagent in ipairs(reagents) do
            if reagent.itemID then
                local name = GetItemInfo(reagent.itemID)
                if name then
                    tinsert(searchTerms, name)
                end
            end
        end

        if #searchTerms > 0 then
            Auctionator.API.v1.MultiSearch("Artisan", searchTerms)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r Поиск " .. #searchTerms .. " реагентов через Auctionator")
            return
        end
    end

    local firstReagent = reagents[1]
    if firstReagent and firstReagent.itemID then
        local _, itemLink = GetItemInfo(firstReagent.itemID)
        if itemLink then
            local box = _G["AuctionHouseFrameSearchBarSearchBox"]
                or _G["AuctionHouseFrameSearchBox"]
                or _G["AuctionFrameBrowseSearchBox"]
            if box then
                box:SetText(itemLink)
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
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]|r Ошибка поиска: " .. tostring(err))
                end
            end
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

-- ============================================================================
-- Учёт продаж (для тултипов «Продажа» и «Прибыль»).
-- Веб-лежащая история хранится в ArtisanDB.sales[персонаж][itemID].
-- На 3.3.5 завершение продажи надёжно определяется по исчезновению лота из
-- вкладки «Мои лоты» (AUCTION_OWNED_LIST_UPDATE). ВНИМАНИЕ: этим способом
-- нельзя отличить «продано» от «истекло»/«отменено», поэтому статистика
-- приблизительная. Прибыль считается как выручка (buyout*0.95) минус
-- стоимость крафта по текущим ценам реагентов.
-- ============================================================================

function Artisan.UI:GetItemIDByName(name)
    if name == nil or name == "" then return nil end
    if not self.NameToItemID then
        local idx = {}
        for profID, recipes in pairs(Artisan.RecipeDB or {}) do
            for sid, data in pairs(recipes) do
                if data.itemID and data.name then
                    idx[data.name] = data.itemID
                end
            end
        end
        self.NameToItemID = idx
    end
    return self.NameToItemID[name]
end

function Artisan.UI:GetCraftCost(itemID)
    local spellID = self:GetSpellIDByItemID(itemID)
    if not spellID then return 0 end
    local data
    for pid, recipes in pairs(Artisan.RecipeDB or {}) do
        if recipes[spellID] then
            data = recipes[spellID]
            break
        end
    end
    if not data or not data.reagents then return 0 end
    local cost = 0
    for rid, cnt in pairs(data.reagents) do
        local p = Artisan.Auctionator and Artisan.Auctionator:GetItemPrice(rid) or 0
        cost = cost + (p or 0) * cnt
    end
    return cost
end

function Artisan.UI:GetSalesForItem(itemID)
    ArtisanDB = ArtisanDB or {}
    if not ArtisanDB.sales then return nil end
    local charName = self:GetCurrentCharKey()
    local rec = ArtisanDB.sales[charName] and ArtisanDB.sales[charName][itemID]
    return rec
end

function Artisan.UI:AddSale(itemID, qty, revenue, profit, charName)
    if not itemID or not qty or qty <= 0 then return end
    charName = charName or self:GetCurrentCharKey()
    if not charName or charName == "" then return end
    ArtisanDB = ArtisanDB or {}
    ArtisanDB.sales = ArtisanDB.sales or {}
    ArtisanDB.sales[charName] = ArtisanDB.sales[charName] or {}
    local rec = ArtisanDB.sales[charName][itemID]
    local t = time()
    if rec then
        rec.qty = (rec.qty or 0) + qty
        rec.revenue = (rec.revenue or 0) + revenue
        rec.profit = (rec.profit or 0) + profit
        rec.count = (rec.count or 0) + 1
        rec.last = t
    else
        ArtisanDB.sales[charName][itemID] = {
            qty = qty,
            revenue = revenue,
            profit = profit,
            count = 1,
            first = t,
            last = t,
        }
    end
end

function Artisan.UI:BuildOwnedSnapshot()
    local snap = {}
    local n = GetNumAuctionItems and GetNumAuctionItems("owner") or 0
    for i = 1, n do
        local name, _, count, _, _, _, _, _, _, buyout = GetAuctionItemInfo("owner", i)
        if name then
            local key = name .. "|" .. (buyout or 0)
            snap[key] = (snap[key] or 0) + (count or 0)
        end
    end
    return snap
end

function Artisan.UI:RefreshOwnedAuctions()
    local current = self:BuildOwnedSnapshot()
    if not self.OwnedReady then
        self.OwnedSnapshot = current
        self.OwnedReady = true
        return
    end
    local prev = self.OwnedSnapshot or {}
    for key, prevCount in pairs(prev) do
        local curCount = current[key] or 0
        if curCount < prevCount then
            local removed = prevCount - curCount
            local name, buyoutStr = key:match("^(.-)|(%d+)$")
            local buyout = tonumber(buyoutStr) or 0
            local itemID = self:GetItemIDByName(name)
            if itemID and buyout and buyout > 0 then
                local cost = self:GetCraftCost(itemID)
                local revenue = buyout * removed * 0.95
                local profit = revenue - cost * removed
                self:AddSale(itemID, removed, revenue, profit)
            end
        end
    end
    self.OwnedSnapshot = current
end

function Artisan.UI:RegisterSalesTracking()
    if self.salesFrame then return end
    local f = CreateFrame("Frame")
    f:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
    f:RegisterEvent("AUCTION_HOUSE_SHOW")
    f:RegisterEvent("AUCTION_HOUSE_CLOSED")
    f:SetScript("OnEvent", function(_, event)
        if event == "AUCTION_OWNED_LIST_UPDATE" then
            Artisan.UI:RefreshOwnedAuctions()
        else
            Artisan.UI.OwnedSnapshot = {}
            Artisan.UI.OwnedReady = false
        end
    end)
    self.salesFrame = f
end
