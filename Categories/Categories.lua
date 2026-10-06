local addonName, Artisan = ...

Artisan.Categories = Artisan.Categories or {}

local fallbackRules = {
    Alchemy = {
        { "Эликсир", "Эликсиры" },
        { "Флакон", "Флаконы" },
        { "Зелье", "Зелья" },
        { "Масло", "Масла" },
        { "Настой", "Настои" },
    },
    Cooking = {
        { "Пир", "Пиры" },
        { "Блюдо", "Блюда" },
        { "Десерт", "Десерты" },
        { "Напиток", "Напитки" },
    },
}

-- @return string
function Artisan.Categories:GetGroup(profID, itemName, itemSubType)
    if itemSubType and itemSubType ~= "" then
        return itemSubType
    end

    local rules = fallbackRules[profID]
    if rules and itemName then
        for _, rule in ipairs(rules) do
            if strfind(itemName, rule[1], 1, true) then
                return rule[2]
            end
        end
    end

    return "Прочее"
end