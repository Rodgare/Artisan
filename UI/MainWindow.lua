local addonName, Artisan = ...

Artisan.UI = Artisan.UI or {}

function Artisan.UI:CreateMainWindow()
    if ArtisanMainFrame then return end

    local frame = CreateFrame("Frame", "ArtisanMainFrame", UIParent)
    tinsert(UISpecialFrames, "ArtisanMainFrame")
    frame:SetSize(800, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN")

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture(0, 0, 0, 0.8)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnMouseDown", function(self, LeftButton)
        if LeftButton == "LeftButton" then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self, LeftButton)
        if LeftButton == "LeftButton" then
            self:StopMovingOrSizing()
        end
    end)

    frame:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
    end)

    frame:Hide();

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
    topBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 4, 0)
    topBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -5, -5)
    topBar:SetHeight(30)

    for idx, prof in ipairs(PROFESSIONS) do
        local btn = CreateFrame("Button", nil, topBar)
        btn:SetPoint("LEFT", topBar, "LEFT", (idx - 1) * 32, -3)
        btn:SetSize(28, 28)
        -- btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

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
            border:Hide()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            Artisan.UI:SelectProfession(prof.id)
        end)
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
end

function Artisan.UI:CreateRecipeList(parentFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "ArtisanRecipeScrollFrame",
        parentFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -32, 10)

    local header = CreateFrame("Frame", nil, parentFrame)
    header:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -38)
    header:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -32, -38)
    header:SetHeight(20)

    local columns = {
        { key = "name", text = "Рецепт", x = 120, width = 240, align = "LEFT" },
        { key = "cost", text = "Затраты", x = 300, width = 120, align = "RIGHT" },
        { key = "sell", text = "Продажа", x = 440, width = 120, align = "RIGHT" },
        { key = "profit", text = "Прибыль", x = 580, width = 140, align = "RIGHT" },
    }
    for _, col in ipairs(columns) do
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(col.width, 18)
        btn:SetPoint("LEFT", header, "LEFT", col.x, 0)
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetAllPoints(btn)
        txt:SetText(col.text)
        txt:SetJustifyH(col.align)
        txt:SetTextColor(0.7, 0.7, 0.7)
        btn:SetScript("OnEnter", function() txt:SetTextColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() txt:SetTextColor(0.7, 0.7, 0.7) end)

        btn:SetScript("OnClick", function()
            --TODO SORT
        end)
    end

    self.RowFrames = {}

    local ROW_HEIGHT = 21

    for i = 1, 20 do
        local row = CreateFrame("Button", nil, parentFrame)
        row:SetSize(750, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0,
            -(i - 1) * ROW_HEIGHT)

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

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            GameTooltip:SetHyperlink("item:" .. self.data.itemID)
            -- print(self.data.itemID)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 21, function()
            Artisan.UI:UpdateScroll()
        end)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentOffset = FauxScrollFrame_GetOffset(self)

        local step = 1
        local newOffset = currentOffset - (delta * step)
        local totalItems = Artisan.UI.CurrentList and #Artisan.UI.CurrentList or 0
        local maxOffset = math.max(0, totalItems - 20)
        if newOffset < 0 then newOffset = 0 end
        if newOffset > maxOffset then newOffset = maxOffset end
        FauxScrollFrame_SetOffset(self, newOffset)
        Artisan.UI:UpdateScroll()
    end)


    self.ScrollFrame = scrollFrame
end

function Artisan.UI:SelectProfession(profID)
    local rawRecipes = Artisan.RecipeDB and Artisan.RecipeDB[profID]
    if not rawRecipes then return end

    local list = {}

    for spellID, data in pairs(rawRecipes) do
        local totalCost = 0

        if data.reagents then
            for reagentID, count in pairs(data.reagents) do
                local price = Artisan.Auctionator:GetItemPrice(reagentID) or 0
                totalCost = totalCost + (price * count)
            end
        end

        local sellPrice = (Artisan.Auctionator:GetItemPrice(data.itemID) or 0) * data.craftCount
        local profit = (sellPrice * 0.95) - totalCost --0.95 auc % TODO проверить

        table.insert(list, {
            spellID = spellID,
            itemID = data.itemID,
            cost = totalCost,
            sell = sellPrice,
            profit = profit,
        })
    end

    table.sort(list, function(a, b)
        return a.profit > b.profit
    end)

    self.CurrentList = list
    self:UpdateScroll()
end

function Artisan.UI:UpdateScroll()
    if not self.CurrentList or not self.ScrollFrame then return end

    local totalItems = #self.CurrentList
    local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)

    FauxScrollFrame_Update(self.ScrollFrame, totalItems, 20, 21)

    for i = 1, 20 do
        local index = offset + i
        local data = self.CurrentList[index]
        local row = self.RowFrames[i]

        if data then
            row:Show()

            local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(data.itemID)

            row.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(itemName or ("ID: " .. data.itemID))
            row.cost:SetText(Artisan.Utils:FormatMoney(data.cost))
            row.sell:SetText(Artisan.Utils:FormatMoney(data.sell))
            row.profit:SetText(Artisan.Utils:FormatMoney(data.profit))

            row.data = data
        else
            row:Hide()
        end
    end
end
