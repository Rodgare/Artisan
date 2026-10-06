local addonName, Artisan = ...

Artisan.Pricing = Artisan.Pricing or {}

local lists = {}
local nameCache = {}
local textureCache = {}
local itemTypeCache = {}
local subTypeCache = {}

local function GetItemInfoCached(itemID)
    if nameCache[itemID] == nil then
        local name, _, _, _, _, itemType, subType, _, _, texture = GetItemInfo(itemID)
        nameCache[itemID] = name
        textureCache[itemID] = texture
        itemTypeCache[itemID] = itemType
        subTypeCache[itemID] = subType
    end
    return nameCache[itemID], textureCache[itemID], itemTypeCache[itemID], subTypeCache[itemID]
end

function Artisan.Pricing:BuildProfessionList(profID)
    local rawRecipes = Artisan.RecipeDB and Artisan.RecipeDB[profID]
    if not rawRecipes then return nil end

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
        local profit = (sellPrice * 0.95) - totalCost -- 0.95 % аукциона

        local itemName, itemTexture, itemType, itemSubType = GetItemInfoCached(data.itemID)

        tinsert(list, {
            spellID = spellID,
            itemID = data.itemID,
            profID = profID,
            itemName = itemName,
            itemTexture = itemTexture,
            group = Artisan.Categories:GetGroup(profID, itemName, itemType, itemSubType),
            cost = totalCost,
            sell = sellPrice,
            profit = profit,
        })
    end

    lists[profID] = list
    return list
end

function Artisan.Pricing:GetProfessionList(profID)
    if not lists[profID] then
        return self:BuildProfessionList(profID)
    end
    return lists[profID]
end

function Artisan.Pricing:RefreshProfession(profID)
    lists[profID] = nil
    return self:BuildProfessionList(profID)
end

function Artisan.Pricing:ClearAll()
    wipe(lists)
end