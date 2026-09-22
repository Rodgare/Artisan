local addonName, Artisan = ...

Artisan.Utils = Artisan.Utils or {}

function Artisan.Utils:FormatMoney(copper)
    if not copper or copper == 0 then return "0г" end
    -- 1. Запоминаем знак и берем абсолютное значение
    local isNegative = copper < 0
    local absCopper = math.abs(copper)
    -- 2. Считаем золото, серебро и медь от положительного числа
    local gold = math.floor(absCopper / 10000)
    local silver = math.floor((absCopper % 10000) / 100)

    local result = string.format("|cffffd700%d|rг |cffc7c7cf%02d|rc", gold, silver)
    -- 3. Добавляем минус, если убыток
    if isNegative then
        return "-" .. result
    end
    return result
end
