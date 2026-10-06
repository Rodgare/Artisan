local addonName, Artisan = ...

---@diagnostic disable-next-line: undefined-global
local Auctionator = Auctionator

Artisan.Auctionator = Artisan.Auctionator or {}

local priceCache = {}

-- @param itemID number ID
-- @return number|nil цена в меди
function Artisan.Auctionator:GetItemPrice(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    if priceCache[itemID] ~= nil then
        return priceCache[itemID]
    end

    local price
    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
        price = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID)
    end

    priceCache[itemID] = price
    return price
end

function Artisan.Auctionator:ClearPriceCache()
    wipe(priceCache)
end