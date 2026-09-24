local addonName, Artisan = ...

Artisan.Utils = Artisan.Utils or {}

function Artisan.Utils:FormatMoney(copper)
    if not copper or copper <= 1000 then return "0г" end

    local isNegative = copper < 0
    local absCopper = math.abs(copper)

    local gold = math.floor(absCopper / 10000)
    -- local silver = math.floor((absCopper % 10000) / 100)

    local result = string.format("%dг", gold)

    -- if isNegative then
    --     return "-" .. result
    -- end
    return result
end
