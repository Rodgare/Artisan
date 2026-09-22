local addonName, Artisan = ...

---@diagnostic disable-next-line: undefined-global
local Auctionator = Auctionator

Artisan.Auctionator = Artisan.Auctionator or {}

-- @param itemID number ID
-- @return number|nil
function Artisan.Auctionator:GetItemPrice(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
        return Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID)
    end

    return nil
end
