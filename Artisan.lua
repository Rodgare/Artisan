local addonName, Artisan = ...

local window = CreateFrame("Frame", "ArtisanMainWindow", UIParent)
Artisan.window = window

window:SetSize(400, 400)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

window:Hide()

local bg = window:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(window)
bg:SetTexture(0, 0, 0, 0.8)

window:EnableMouse(true)
window:SetMovable(true)
window:RegisterForDrag("LeftButton")
window:SetScript("OnDragStart", window.StartMoving)
window:SetScript("OnDragStop", window.StopMovingOrSizing)

local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", window, "TOP", 0, -10)
title:SetText("window 400x400px")
