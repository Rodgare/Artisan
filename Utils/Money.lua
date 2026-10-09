local addonName, Artisan = ...

Artisan.Utils = Artisan.Utils or {}

-- local function GroupGold(gold)
--     local s = tostring(gold)
--     local out = {}
--     local count = 0
--     for i = #s, 1, -1 do
--         count = count + 1
--         tinsert(out, 1, s:sub(i, i))
--         if count % 3 == 0 and i > 1 then
--             tinsert(out, 1, " ")
--         end
--     end
--     return table.concat(out)
-- end

-- Цветное форматирование: 123г или 12г5с, золото -- жёлтое, серебро -- серебристое.
-- Медь не показываем совсем; при цене от 100г серебро тоже скрываем.
function Artisan.Utils:FormatMoney(copper)
    if not copper then copper = 0 end

    local sign = ""
    if copper < 0 then
        sign = "-"
        copper = -copper
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)

    local parts = {}
    if gold > 0 then tinsert(parts, gold .. "|cffffd700г|r") end
    if silver > 0 and gold < 100 then tinsert(parts, silver .. "|cffc7c7cfс|r") end

    if #parts == 0 then
        return sign .. "0"
    end
    return sign .. table.concat(parts)
end

-- Без цветов, для мест, где нужен только текст (склеивание в строку).
function Artisan.Utils:FormatMoneyRaw(copper)
    if not copper then copper = 0 end

    local sign = ""
    if copper < 0 then
        sign = "-"
        copper = -copper
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)

    local parts = {}
    if gold > 0 then tinsert(parts, gold .. "г") end
    if silver > 0 and gold < 100 then tinsert(parts, silver .. "с") end

    if #parts == 0 then
        return sign .. "0"
    end
    return sign .. table.concat(parts)
end