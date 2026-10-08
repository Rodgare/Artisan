local addonName, Artisan = ...

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "Artisan" then
        if Artisan.UI and Artisan.UI.InitKnownRecipesDB then
            Artisan.UI:InitKnownRecipesDB()
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

SLASH_ARTISAN1 = "/artisan"
SLASH_ARTISAN2 = "/art"

SlashCmdList["ARTISAN"] = function(msg)
    local itemID = tonumber(msg) or 36901
    local price = Artisan.Auctionator:GetItemPrice(itemID)
    ---@diagnostic disable-next-line: deprecated
    local _, itemLink = GetItemInfo(itemID)

    if price then
        local formattedPrice = Artisan.Utils:FormatMoney(price)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Artisan]:|r Цена %s: %s", itemLink or ("ID " .. itemID), formattedPrice))
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Artisan]:|r Для предмета %s нет данных в Auctionator!", itemLink or ("ID " .. itemID)))
    end
end

SLASH_ARTISANDB1 = "/artisandb"
SlashCmdList["ARTISANDB"] = function()
    ArtisanDB = ArtisanDB or {}
    ArtisanDB.knownRecipes = ArtisanDB.knownRecipes or {}
    local charKey = UnitName("player") or "?"
    local count = 0
    if ArtisanDB.knownRecipes[charKey] then
        for _ in pairs(ArtisanDB.knownRecipes[charKey]) do count = count + 1 end
    end
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Artisan]|r SavedVariables: %d рецептов для %s", count, charKey))
    for char, recipes in pairs(ArtisanDB.knownRecipes) do
        local c = 0
        for _ in pairs(recipes) do c = c + 1 end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %d рецептов", char, c))
    end
end