local addonName, Artisan = ...

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    if Artisan.UI and Artisan.UI.InitKnownRecipesDB then
        Artisan.UI:InitKnownRecipesDB()
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