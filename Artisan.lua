--Скрытие цены стоимости крафта Auctionator
if AuctionatorReagentSearchButtonMixin then
    function AuctionatorReagentSearchButtonMixin:UpdateTotal()
    end
    print("|cff00ff00Artisan:|r Текст Auctionator успешно заблокирован.")
else
    print("|cffff0000Artisan:|r Не удалось найти Auctionator для блокировки.")
end

local REAGENTS_FROM_VENDOR = {
    -- === АЛХИМИЯ И НАЧЕРТАНИЕ (Колбы и Пергаменты) ===
    ["3371"]  = 2,   -- Пустая колба
    ["3372"]  = 10,  -- Свинцовая колба
    ["3827"]  = 50,  -- Магическая колба
    ["18256"] = 250, -- Исполинская колба
    ["3935"]  = 10,  -- Черный купорос (иногда у вендоров)
    ["35948"] = 10,  -- Очищенная колба
    ["35947"] = 50,  -- Колба из-под ледяного молока
    ["37201"] = 50,  -- Хрустальная колба
    ["39501"] = 50,  -- Тонкий пергамент
    ["39502"] = 125, -- Плотный пергамент
    ["39505"] = 250, -- Чистый пергамент (Sirus/WotLK)

    -- === ПОРТНЯЖНОЕ ДЕЛО И КОЖЕВНИЧЕСТВО (Нитки и Краски) ===
    ["2320"]  = 10,   -- Грубая нить
    ["2321"]  = 50,   -- Тонкая нить
    ["4291"]  = 100,  -- Шелковая нить
    ["8343"]  = 500,  -- Толстая шелковая нить
    ["14341"] = 1250, -- Руническая нить
    ["38426"] = 4000, -- Этерниевая нить
    ["2324"]  = 10,   -- Отбеливатель
    ["2325"]  = 10,   -- Черная краска
    ["4340"]  = 250,  -- Серая краска
    ["4341"]  = 500,  -- Желтая краска
    ["4342"]  = 1000, -- Пурпурная краска
    ["10290"] = 1000, -- Розовая краска
    ["2604"]  = 10,   -- Соль
    ["10647"] = 1000, -- Очищенная соль

    -- === КУЗНЕЧНОЕ ДЕЛО И ИНЖЕНЕРНОЕ ДЕЛО ===
    ["2880"]  = 10,    -- Слабый плавень
    ["3857"]  = 200,   -- Сильный плавень
    ["17030"] = 5000,  -- Оскверненный плавень
    ["17034"] = 1500,  -- Уголь
    ["17035"] = 7500,  -- Арканитовый преобразователь
    ["18567"] = 10000, -- Элементиевый плавень
    ["4358"]  = 200,   -- Гремучая ртуть
    ["10648"] = 500,   -- Пустой баллон
    ["4389"]  = 10,    -- Гироскопический шестерни (иногда)
    ["2323"]  = 20,    -- Льняная лента

    -- === НАЛОЖЕНИЕ ЧАР (Инструменты) ===
    ["6217"]  = 15,   -- Медный жезл
    ["6218"]  = 450,  -- Посеребренный жезл (у торговца сопутствующими товарами)
    ["44452"] = 1800, -- Простая древесина
    ["44454"] = 4500, -- Звездная древесина

    -- === КУЛИНАРИЯ ===
    ["2678"]  = 2,  -- Родниковая вода
    ["3725"]  = 10, -- Пряные травы
    ["4604"]  = 20, -- Ледяное молоко
    ["1708"]  = 5,  -- Сладкий нектар
    ["2692"]  = 40, -- Острые специи
}

local function FormatMoney(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)

    local res = ""
    res = res .. gold .." " .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:2|t "
    res = res .. silver .. " " .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:2|t "

    return res
end

local function GetItemPrice(id)
    local sId = tostring(id)
    local itemData = Auctionator.Database.db[sId]
    local auctionPrice = itemData and itemData.m or 9999999

    local vendorPrice = REAGENTS_FROM_VENDOR[sId]

    if vendorPrice and vendorPrice < auctionPrice then
        return vendorPrice
    end

    return auctionPrice == 9999999 and 0 or auctionPrice
end

local function GetCraftCost()
    local receptId = GetTradeSkillSelectionIndex()
    local numReagents = GetTradeSkillNumReagents(receptId)
    local totalCost = 0

    for i = 1, numReagents do
        local _, _, count = GetTradeSkillReagentInfo(receptId, i)
        local reagentLink = GetTradeSkillReagentItemLink(receptId, i)

        if reagentLink then
            local itemId = reagentLink:match("item:(%d+)")

            local price = GetItemPrice(itemId)
            totalCost = totalCost + (price * count)
        end
    end

    return totalCost
end

local function GetSellPrice()
    local receptId = GetTradeSkillSelectionIndex()
    local itemLink = GetTradeSkillItemLink(receptId)

    if not itemLink then return 0 end

    local itemId = itemLink:match("item:(%d+)")
    local numMade = GetTradeSkillNumMade(receptId)

    return GetItemPrice(itemId) * (numMade or 1)
end

local priceText = TradeSkillDetailScrollChildFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
priceText:SetPoint("TOPLEFT", TradeSkillDetailScrollChildFrame, "TOPLEFT", 65, -47)

local profitText = TradeSkillDetailScrollChildFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profitText:SetPoint("TOPLEFT", TradeSkillDetailScrollChildFrame, "TOPLEFT", 65, -60)

local masterText = TradeSkillDetailScrollChildFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
masterText:SetPoint("TOPLEFT", TradeSkillDetailScrollChildFrame, "TOPLEFT", 65, -107)

hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
    local currentCraftCost = GetCraftCost()
    local sellPrice = GetSellPrice()

    priceText:SetText("|cffffd100Крафт:|r " .. FormatMoney(currentCraftCost))

    local profit = sellPrice - currentCraftCost

    profitText:SetText("|cffffd100Доход:|r " .. FormatMoney(profit) .. "|r")

    -- local masterProfit = (sellPrice * 1.2) - currentCraftCost
    -- masterText:SetText("|cffffd100Мастер (x1.2):|r " .. FormatMoney(masterProfit))
end)
