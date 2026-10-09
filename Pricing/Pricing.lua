local addonName, Artisan = ...

Artisan.Pricing = Artisan.Pricing or {}

local lists = {}
local nameCache = {}
local textureCache = {}
local itemTypeCache = {}
local subTypeCache = {}

local maxSkill = nil
local function GetMaxSkill()
    if maxSkill ~= nil then return maxSkill end
    maxSkill = 0
    if Artisan.RecipeSources then
        for _, src in pairs(Artisan.RecipeSources) do
            if src and src.skill and src.skill > maxSkill then
                maxSkill = src.skill
            end
        end
    end
    return maxSkill
end

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

        local src = Artisan.RecipeSources and Artisan.RecipeSources[spellID]
        local skillText = ""
        if src and src.skill then
            if src.skill >= GetMaxSkill() then
                skillText = tostring(src.skill)
            else
                skillText = tostring(src.skill)
                if src.medium then skillText = skillText .. "/" .. src.medium end
                if src.easy then skillText = skillText .. "/" .. src.easy end
                if src.trivial then skillText = skillText .. "/" .. src.trivial end
            end
        end

        local reagents = {}
        if data.reagents then
            for reagentID, count in pairs(data.reagents) do
                local rName, rTexture = GetItemInfoCached(reagentID)
                tinsert(reagents, {
                    itemID = reagentID,
                    count = count,
                    icon = rTexture,
                    name = rName,
                })
            end
        end

        tinsert(list, {
            spellID = spellID,
            itemID = data.itemID,
            profID = profID,
            itemName = itemName,
            itemTexture = itemTexture,
            group = Artisan.Categories:GetGroup(profID, itemName, itemType, itemSubType),
            bop = data.bonding == 1,
            cost = totalCost,
            sell = sellPrice,
            profit = profit,
            skill = src and src.skill,
            skillText = skillText,
            reagents = reagents,
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