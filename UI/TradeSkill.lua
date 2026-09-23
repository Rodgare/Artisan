local addonName, Artisan = ...

local function PrintSelectedRecipeReagents()
    local selectionIndex = GetTradeSkillSelectionIndex()
    if not selectionIndex or selectionIndex == 0 then return end

    local numReagents = GetTradeSkillNumReagents(selectionIndex)
    print("--- Выбран рецепт #" .. selectionIndex .. " (Реагентов: " .. numReagents .. ") ---")

    for i = 1, numReagents do
        local name, _, count = GetTradeSkillReagentInfo(selectionIndex, i)
        local link = GetTradeSkillReagentItemLink(selectionIndex, i)

        local itemID = link and tonumber(link:match("item:(%d+)"))

        print(string.format("  Реагент %d: %s (x%d) [ID: %s]", i, name or "???", count or 0, itemID or "nil"))
    end
end

local function OnTradeSkillLoaded()
    if TradeSkillFrame_SetSelection then
        hooksecurefunc("TradeSkillFrame_SetSelection", function(index)
            PrintSelectedRecipeReagents()
        end)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "Blizzard_TradeSkillUI" then
        OnTradeSkillLoaded()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

if IsAddOnLoaded("Blizzard_TradeSkillUI") then
    OnTradeSkillLoaded()
end
