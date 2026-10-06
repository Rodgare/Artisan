local addonName, Artisan = ...

Artisan.Categories = Artisan.Categories or {}

local useClass = {
    ["Сумки"] = true,
    ["Снаряжение"] = true,
    ["Боеприпасы"] = true,
    ["Самоцветы"] = true,
    ["Зелья"] = true,
    ["Еда и напитки"] = true,
    ["Эликсиры"] = true,
    ["Настойки"] = true,
    ["Доспехи"] = true,
    ["Оружие"] = true,
    ["Рецепты"] = true,
    ["Символы"] = true,
    ["Хозяйственные товары"] = true,
    ["Разное"] = true,
}

function Artisan.Categories:GetGroup(profID, itemName, itemType, itemSubType)
    if itemType and itemType ~= "" then
        if not useClass[itemType] and itemSubType and itemSubType ~= "" then
            return itemSubType
        end
        return itemType
    end

    if itemSubType and itemSubType ~= "" then
        return itemSubType
    end

    return "Прочее"
end