local addonName, Artisan = ...

Artisan.Utils = Artisan.Utils or {}

-- @param copper number 
-- @return string
function Artisan.Utils:FormatMoney(copper)
    if not copper or copper <= 0 then
        return "|cff808080Нет данных|r"
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)

    local result = ""
    if gold > 0 then
        result = result .. string.format("|cffffd700%d|rg ", gold)
    end
    if silver > 0 or gold > 0 then
        result = result .. string.format("|cffc7c7cf%d|rs ", silver)
    end

    return result
end