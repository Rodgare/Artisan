local addonName, Artisan = ...

Artisan.Utils = Artisan.Utils or {}

local function GroupGold(gold)
    local s = tostring(gold)
    local out = {}
    local count = 0
    for i = #s, 1, -1 do
        count = count + 1
        tinsert(out, 1, s:sub(i, i))
        if count % 3 == 0 and i > 1 then
            tinsert(out, 1, " ")
        end
    end
    return table.concat(out)
end

function Artisan.Utils:FormatMoney(copper)
    if not copper or copper == 0 then return "0|cffffd700г|r" end

    local sign = ""
    if copper < 0 then
        sign = "-"
        copper = -copper
    end

    local gold = math.floor(copper / 10000)
    if gold < 1 then return sign .. "0|cffffd700г|r" end

    return sign .. GroupGold(gold) .. "|cffffd700г|r"
end

function Artisan.Utils:FormatMoneyRaw(copper)
    if not copper or copper == 0 then return "0г" end

    local sign = ""
    if copper < 0 then
        sign = "-"
        copper = -copper
    end

    local gold = math.floor(copper / 10000)
    if gold < 1 then return sign .. "0г" end

    return sign .. GroupGold(gold) .. "г"
end