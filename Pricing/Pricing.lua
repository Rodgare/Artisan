local addonName, Artisan = ...

Artisan.Pricing = Artisan.Pricing or {}

local lists = {}
local nameCache = {}
local textureCache = {}
local itemTypeCache = {}
local subTypeCache = {}
local ilvlCache = {}
local qualityCache = {}

local ITEM_CLASS_CONSUMABLE = 0
local ALCH_SPEC = {
    potions       = { chance = 0.15, label = "Мастер зелий",       subsPat = { "зель", "potion", "фляг", "flask" } },
    elixirs       = { chance = 0.10, label = "Мастер эликсиров",   subsPat = { "эликсир", "элексир", "настой", "elixir" } },
    transmutation = { chance = 0.15, label = "Мастер трансмутации", nonConsumable = true },
}
local subNameToId = {}
local craftSubCache = {}
local resolvedSubs = {}

local function EnsureSubMap()
    if next(subNameToId) ~= nil then return end
    for i = 0, 40 do
        local s = GetItemSubClassInfo(ITEM_CLASS_CONSUMABLE, i)
        if s and s ~= "" then subNameToId[s] = i end
    end
end

local function FindSubId(...)
    EnsureSubMap()
    for n = 1, select("#", ...) do
        local pat = select(n, ...)
        for name, id in pairs(subNameToId) do
            if name:lower():find(pat, 1, true) then return id end
        end
    end
    return nil
end

local function GetCraftSubClass(itemID)
    if craftSubCache[itemID] ~= nil then return craftSubCache[itemID] end
    EnsureSubMap()
    local itemType = select(6, GetItemInfo(itemID))
    local itemSub = select(7, GetItemInfo(itemID))
    if itemType and itemType == GetItemClassInfo(ITEM_CLASS_CONSUMABLE) and subNameToId[itemSub] ~= nil then
        craftSubCache[itemID] = subNameToId[itemSub]
    else
        craftSubCache[itemID] = -1
    end
    return craftSubCache[itemID]
end

local function ResolveSubs(specKey)
    if resolvedSubs[specKey] then return resolvedSubs[specKey] end
    local cfg = ALCH_SPEC[specKey]
    local ids = {}
    if not cfg.nonConsumable then
        for _, pat in ipairs(cfg.subsPat) do
            local id = FindSubId(pat)
            if id then ids[id] = true end
        end
    end
    resolvedSubs[specKey] = ids
    return ids
end

function Artisan.Pricing:GetAlchemySpec()
    ArtisanDB = ArtisanDB or {}
    return ALCH_SPEC[ArtisanDB.alchemySpec] and ArtisanDB.alchemySpec or nil
end

function Artisan.Pricing:GetAlchemySpecLabel()
    local s = self:GetAlchemySpec()
    return s and ALCH_SPEC[s].label or "Нет"
end

function Artisan.Pricing:SetAlchemySpec(spec)
    ArtisanDB = ArtisanDB or {}
    ArtisanDB.alchemySpec = ALCH_SPEC[spec] and spec or nil
end

function Artisan.Pricing:GetYieldMultiplier(itemID)
    local s = self:GetAlchemySpec()
    if not s then return 1 end
    local cfg = ALCH_SPEC[s]
    local sub = GetCraftSubClass(itemID)
    if cfg.nonConsumable then
        if sub == -1 then return 1 + cfg.chance end
        return 1
    end
    if ResolveSubs(s)[sub] then return 1 + cfg.chance end
    return 1
end

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
        local name, _, rarity, itemLevel = GetItemInfo(itemID)
        local _, _, _, _, _, itemType, subType, _, _, texture = GetItemInfo(itemID)
        nameCache[itemID] = name
        textureCache[itemID] = texture
        itemTypeCache[itemID] = itemType
        subTypeCache[itemID] = subType
        ilvlCache[itemID] = itemLevel
        qualityCache[itemID] = rarity
    end
    return nameCache[itemID], textureCache[itemID], itemTypeCache[itemID], subTypeCache[itemID], ilvlCache[itemID], qualityCache[itemID]
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

        local yieldMult = self:GetYieldMultiplier(data.itemID)
        local sellPrice = (Artisan.Auctionator:GetItemPrice(data.itemID) or 0) * data.craftCount * yieldMult
        local profit = (sellPrice * 0.95) - totalCost -- 0.95 % аукциона

        local itemName, itemTexture, itemType, itemSubType, itemILvl, itemQuality = GetItemInfoCached(data.itemID)

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
            yield = yieldMult,
            ilvl = itemILvl,
            quality = itemQuality,
            skill = src and src.skill,
            trivial = src and src.trivial,
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

function Artisan.Pricing:RefreshItemPrice(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end

    for profID, plist in pairs(lists) do
        local rawProf = Artisan.RecipeDB and Artisan.RecipeDB[profID]
        if rawProf then
            for _, row in ipairs(plist) do
                if row.itemID == itemID then
                    local data = rawProf[row.spellID]
                    if data then
                        local totalCost = 0
                        if data.reagents then
                            for reagentID, count in pairs(data.reagents) do
                                local price = Artisan.Auctionator:GetItemPrice(reagentID) or 0
                                totalCost = totalCost + (price * count)
                            end
                        end

                        local yieldMult = self:GetYieldMultiplier(data.itemID)
                        local sellPrice = (Artisan.Auctionator:GetItemPrice(data.itemID) or 0) * data.craftCount * yieldMult
                        local profit = (sellPrice * 0.95) - totalCost

                        row.cost = totalCost
                        row.sell = sellPrice
                        row.profit = profit
                    end
                end
            end
        end
    end
end