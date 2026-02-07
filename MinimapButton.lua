local currentAngle = 45

local function UpdateButtonPosition(angle)
    local radius = 80
    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius
    MyProfitMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local MiniButton = CreateFrame("Button", "MyProfitMinimapButton", Minimap)
MiniButton:SetSize(33, 33)
MiniButton:SetFrameStrata("MEDIUM")
MiniButton:SetFrameLevel(10)
MiniButton:EnableMouse(true)
MiniButton:SetMovable(true)
MiniButton:RegisterForDrag("LeftButton")

local icon = MiniButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Inv_misc_gear_01")
icon:SetSize(21, 21)
icon:SetPoint("CENTER")

local border = MiniButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(56, 56)
border:SetPoint("TOPLEFT")

local highlight = MiniButton:CreateTexture(nil, "HIGHLIGHT")
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetSize(32, 32)
highlight:SetPoint("CENTER")
highlight:SetBlendMode("ADD")

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Artisan" then
        if not ArtisanSettings then 
            ArtisanSettings = { angle = 45 } 
        end
        currentAngle = ArtisanSettings.angle
        UpdateButtonPosition(currentAngle)
        -- print("|cff00ff00Artisan:|r Настройки загружены, угол:", math.floor(currentAngle))
    end
end)

MiniButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        local cx, cy = Minimap:GetCenter()

        currentAngle = math.deg(math.atan2(my - cy, mx - cx))
        UpdateButtonPosition(currentAngle)
    end)
end)

MiniButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    if ArtisanSettings then
        ArtisanSettings.angle = currentAngle
        -- print("|cff00ff00Artisan:|r Позиция сохранена в память!")
    end
end)

MiniButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if MyProfitAnalysisFrame then
            if MyProfitAnalysisFrame:IsShown() then MyProfitAnalysisFrame:Hide() else MyProfitAnalysisFrame:Show() end
        end
    end
end)