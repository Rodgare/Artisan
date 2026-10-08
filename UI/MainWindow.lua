local addonName, Artisan = ...

Artisan.UI = Artisan.UI or {}

local LAYOUT = {
    frameWidth = 800, frameHeight = 600,
    iconX = 4, iconSize = 18, nameX = 120, nameWidth = 100,
    colCostX = 200, colCostWidth = 100,
    colSellX = 260, colSellWidth = 100,
    colProfitX = 320, colProfitWidth = 110,
    btnCraftRightX = 750, btnReagentsRightX = 685,
    btnWidth = 60, btnReagentsWidth = 65, btnGap = 2,
}

local ROW_HEIGHT = 21
local VISIBLE_ROWS = 23
local WHEEL_STEP = 5

local CATEGORY_ROWS_MAX = 6
local CATEGORY_ROW_HEIGHT = 15

local COLUMNS = {
    { key = "name",   text = "Рецепт",   x = LAYOUT.nameX, width = LAYOUT.nameWidth, align = "LEFT",  sortKey = "itemName" },
    { key = "cost",   text = "Затраты",  x = LAYOUT.colCostX, width = LAYOUT.colCostWidth, align = "RIGHT", sortKey = "cost" },
    { key = "sell",   text = "Продажа",  x = LAYOUT.colSellX, width = LAYOUT.colSellWidth, align = "RIGHT", sortKey = "sell" },
    { key = "profit", text = "Прибыль",  x = LAYOUT.colProfitX, width = LAYOUT.colProfitWidth, align = "RIGHT", sortKey = "profit" },
}

local REAGENT_ICON_SIZE = 16
local REAGENT_ICON_GAP = 2
local MAX_REAGENT_ICONS = 5
local REAGENT_X = LAYOUT.reagentX

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
        Artisan.UI:ScanKnownRecipes()
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
    filterBox:SetSize(180, 20)
    filterBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -40)
    filterBox:SetAutoFocus(false)
    filterBox:SetTextInsets(10, 18, 0, 0)

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
    showBop:SetPoint("LEFT", filterBox, "RIGHT", 8, 0)
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
    showKnown:SetPoint("LEFT", showBop, "RIGHT", 8, 0)
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
    header:SetPoint("TOPLEFT", filterBox, "BOTTOMLEFT", 0, -10)
    header:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, 0)
    header:SetHeight(20)

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

        -- Helper to create styled button
        local function CreateStyledButton(parent, text, width, onClick)
            local btn = CreateFrame("Button", nil, parent)
            btn:SetSize(width, 20)

            -- Gray background
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture("Interface/Buttons/WHITE8X8")
            bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
            btn.bg = bg

            -- Subtle border
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
                if enabled then
                    self:Enable()
                    self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                    self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                    self.txt:SetTextColor(1, 0.82, 0)
                    self.txt:SetText("Крафт")
                else
                    self:Disable()
                    self.bg:SetVertexColor(0.12, 0.12, 0.12, 0.7)
                    self.border:SetVertexColor(0.25, 0.2, 0.15, 0.8)
                    self.txt:SetTextColor(0.5, 0.45, 0.35)
                end
            end

            return btn
        end

        row.craftBtn = CreateStyledButton(row, "Крафт", 60, function(self)
            if row.data and row.data.spellID then
                Artisan.UI:OpenCraftWindow(row.data.spellID, row.data.profID)
            end
        end)
        row.craftBtn:SetPoint("LEFT", row, "LEFT", LAYOUT.btnCraftRightX - LAYOUT.btnWidth, 0)
        row.craftBtn:Hide()

        row.reagentsBtn = CreateStyledButton(row, "Купить", 65, function(self)
            if row.data and row.data.reagents then
                Artisan.UI:SearchReagentsOnAH(row.data.reagents)
            end
        end)
        row.reagentsBtn:SetPoint("RIGHT", row.craftBtn, "LEFT", -2, 0)
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
            if self:IsEnabled() then
                self.bg:SetVertexColor(0.35, 0.35, 0.5, 1)
                self.border:SetVertexColor(0.9, 0.75, 0.3, 1)
                self.txt:SetTextColor(1, 1, 1)
            end
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self:IsEnabled() then
                GameTooltip:SetText("Открыть окно крафта", 1, 1, 1)
            else
                GameTooltip:SetText("Рецепт не изучен", 0.7, 0.7, 0.7)
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

            GameTooltip:Show()
        end)
        row.craftBtn:SetScript("OnLeave", function(self)
            -- Restore visual
            if self:IsEnabled() then
                self.bg:SetVertexColor(0.2, 0.2, 0.2, 0.95)
                self.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                self.txt:SetTextColor(1, 0.82, 0)
            else
                self.bg:SetVertexColor(0.15, 0.1, 0.1, 0.7)
                self.border:SetVertexColor(0.5, 0.2, 0.2, 0.8)
                self.txt:SetTextColor(0.5, 0.25, 0.25)
            end
            GameTooltip:Hide()
        end)

        self.RowFrames[i] = row
    end

    -- Known recipes cache (scanned from TradeSkill window + persisted)
    Artisan.UI.KnownRecipes = Artisan.UI.KnownRecipes or {}
    Artisan.UI.KnownRecipesByProf = Artisan.UI.KnownRecipesByProf or {}
    Artisan.UI.KnownRecipesByChar = Artisan.UI.KnownRecipesByChar or {}

    Artisan.UI.CurrentCharKey = UnitName("player") .. "-" .. GetRealmName()

    function Artisan.UI:InitKnownRecipesDB()
        ArtisanDB = ArtisanDB or {}
        ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}
        ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] = ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] or {}

        -- Load saved recipes into memory
        for spellID in pairs(ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey]) do
            Artisan.UI.KnownRecipes[spellID] = true
        end
    end

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
                if link then
                    local spellID = tonumber(link:match("enchant:(%d+)"))
                    if spellID then
                        Artisan.UI.KnownRecipes[spellID] = true
                        Artisan.UI.KnownRecipesByProf[profName][spellID] = true
                        Artisan.UI.KnownRecipesByChar[Artisan.UI.CurrentCharKey][spellID] = true
                        newRecipes[spellID] = true
                    end
                end
            end
        end

        -- Persist new recipes
        if next(newRecipes) then
            ArtisanDB = ArtisanDB or {}
            ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}
            ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] = ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey] or {}
            for spellID in pairs(newRecipes) do
                ArtisanDB.knownRecipes[Artisan.UI.CurrentCharKey][spellID] = true
            end
        end
    end

    -- Force save on logout
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
        nameButton:SetSize(200, ROW_HEIGHT)
        nameButton:SetPoint("LEFT", row, "LEFT", 28, 0)
        nameButton:SetScript("OnEnter", function(self)
            if not row.data then return end
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. row.data.itemID)
            GameTooltip:Show()
        end)
        nameButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        nameButton:SetScript("OnClick", function(self, button)
            if button == "LeftButton" and IsShiftKeyDown() and row.data then
                Artisan.UI:SearchOnAuctionHouse(row.data.itemName)
            end
        end)

        local costButton = CreateFrame("Button", nil, row)
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
                    GameTooltip:AddLine(iconStr .. "  " .. (itemLink or (itemName or ("ID: " .. rg.itemID))) .. "  x" .. rg.count .. "  |cffffffff" .. priceStr .. "|r" .. qtyStr, 1, 1, 1)
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Итого: |cff00ff00" .. Artisan.Utils:FormatMoneyRaw(row.data.cost) .. "|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        costButton:SetScript("OnLeave", function()
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

function Artisan.UI:SetShowBOP(show)
    self.ShowBOP = show and true or false
    self:RefreshList()
end

function Artisan.UI:SetShowKnown(show)
    self.ShowKnown = show and true or false
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

            row.data = data

            -- Craft button
            local craftBtn = row.craftBtn
            local reagentsBtn = row.reagentsBtn
            if data.spellID then
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
        else
            row:Hide()
            row.craftBtn:Hide()
            row.reagentsBtn:Hide()
        end
    end
end

function Artisan.UI:OpenCraftWindow(spellID, profID)
    if not spellID then return end

    local profSpell = Artisan.UI:GetProfessionSpell(profID)
    if not profSpell then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Неизвестная профессия: " .. tostring(profID))
        return
    end

    -- Open the profession window
    CastSpellByName(profSpell)

    -- Wait for trade skill window to open, then select the recipe
    local waitFrame = CreateFrame("Frame")
    local elapsed = 0
    waitFrame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed > 2 then
            self:SetScript("OnUpdate", nil)
            return
        end
        if TradeSkillFrame and TradeSkillFrame:IsShown() then
            self:SetScript("OnUpdate", nil)
            -- Find the recipe index
            for i = 1, GetNumTradeSkills() do
                local link = GetTradeSkillRecipeLink(i)
                if link then
                    local sID = tonumber(link:match("enchant:(%d+)"))
                    if sID == spellID then
                        TradeSkillFrame_SetSelection(i)
                        TradeSkillFrame_Update()
                        break
                    end
                end
            end
        end
    end)
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

    -- Use Auctionator's MultiSearch API - searches multiple items at once
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

    -- Fallback: search first reagent manually
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
