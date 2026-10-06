local addonName, Artisan = ...

Artisan.Debug = Artisan.Debug or {}

local DB_KEY = "ArtisanDebugDB"
if not _G[DB_KEY] then _G[DB_KEY] = {} end
local debugDB = _G[DB_KEY]

local function AddLine(out, line)
    out[#out + 1] = line
end

local function ShallowDump(name, value, out, depth)
    depth = depth or 0
    if depth > 4 then return end
    local t = type(value)
    if t == "table" then
        AddLine(out, name .. " = TABLE")
        for k, v in pairs(value) do
            ShallowDump(name .. "." .. tostring(k), v, out, depth + 1)
        end
    elseif t == "function" then
        AddLine(out, name .. " = function")
    else
        AddLine(out, name .. " = " .. tostring(value))
    end
end

function Artisan.Debug:RunDump()
    local out = {}
    AddLine(out, "timestamp = " .. date("%Y-%m-%d %H:%M:%S"))

    if Auctionator and Auctionator.API then
        AddLine(out, "-- Auctionator.API --")
        ShallowDump("Auctionator.API", Auctionator.API, out)
    else
        AddLine(out, "Auctionator.API = nil")
    end

    AddLine(out, "-- AUCTION_HOUSE_FILTER_CATEGORY_STRINGS --")
    if AUCTION_HOUSE_FILTER_CATEGORY_STRINGS then
        ShallowDump("AUCTION_HOUSE_FILTER_CATEGORY_STRINGS", AUCTION_HOUSE_FILTER_CATEGORY_STRINGS, out)
    else
        AddLine(out, "AUCTION_HOUSE_FILTER_CATEGORY_STRINGS = nil")
    end

    AddLine(out, "-- Дерево категорий аукциона --")
    if GetAuctionItemClasses then
        local n = select("#", GetAuctionItemClasses())
        AddLine(out, "classes count = " .. tostring(n))
        for i = 1, n do
            local cls = select(i, GetAuctionItemClasses())
            AddLine(out, ("  [%d] %s"):format(i, tostring(cls)))

            local subList
            if GetAuctionItemSubClasses then
                subList = { GetAuctionItemSubClasses(i) }
            end
            if subList and #subList > 0 then
                for j = 1, #subList do
                    AddLine(out, ("    [%d] %s"):format(j, tostring(subList[j])))
                end
            end
        end
    else
        AddLine(out, "GetAuctionItemClasses = nil")
    end

    debugDB.lastDump = out
    local lines = #out
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]|r Дампа готов: " .. lines .. " строк. Читать: /artdb print [стр], всего страниц: " .. math.ceil(lines / 25))
end

function Artisan.Debug:PrintDump(page)
    local out = debugDB.lastDump
    if not out then
        DEFAULT_CHAT_FRAME:AddMessage("[Artisan] Дампа ещё нет. Сначала /artdb")
        return
    end
    local pageSize = 25
    local totalPages = math.max(1, math.ceil(#out / pageSize))
    page = tonumber(page) or 1
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    DEFAULT_CHAT_FRAME:AddMessage(("|cff888888[Artisan]|r Страница %d/%d"):format(page, totalPages))
    local start = (page - 1) * pageSize + 1
    local stop = math.min(#out, start + pageSize - 1)
    for i = start, stop do
        DEFAULT_CHAT_FRAME:AddMessage(out[i])
    end
end

function Artisan.Debug:QueryItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        DEFAULT_CHAT_FRAME:AddMessage("[Artisan] Укажи ID: /artdb item 12345")
        return
    end

    local rec = {
        itemID = itemID,
        timestamp = date("%Y-%m-%d %H:%M:%S"),
    }

    local name, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
    rec.name = name
    rec.itemType = itemType
    rec.itemSubType = itemSubType

    local price = Artisan.Auctionator:GetItemPrice(itemID)
    rec.price = price

    debugDB.itemQueries = debugDB.itemQueries or {}
    tinsert(debugDB.itemQueries, rec)

    DEFAULT_CHAT_FRAME:AddMessage(("|cff00ff00[Artisan]|r %s (ID %d): тип='%s' подтип='%s' цена=%s"):format(
        tostring(name), itemID, tostring(itemType), tostring(itemSubType), tostring(price)))
end

SLASH_ARTDB1 = "/artdb"
SLASH_ARTDB2 = "/artdebug"
SlashCmdList["ARTDB"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    cmd = strlower(cmd or "")
    if cmd == "item" then
        Artisan.Debug:QueryItem(arg)
    elseif cmd == "print" then
        Artisan.Debug:PrintDump(arg)
    else
        Artisan.Debug:RunDump()
    end
end