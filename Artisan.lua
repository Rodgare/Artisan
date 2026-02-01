local function FormatMoney(amount)
    if not amount or amount <= 0 then 
        return "0 |TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t" 
    end

    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)

    local res = ""
    if gold > 0 then
        res = res .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:2|t "
    end
    if silver > 0 or gold > 0 then
        res = res .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:2|t "
    end
    
    return res
end

local function GetItemPrice(id)
    return Auctionator.Database.db[tostring(id)].m
end

local function GetCost()
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

local priceText = TradeSkillDetailScrollChildFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
priceText:SetPoint("CENTER", TradeSkillDetailScrollChildFrame, "TOP", -14, -67)

hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
    local currentCost = GetCost()
    
    if currentCost and currentCost > 0 then
        priceText:SetText("|cffffd100Крафт:|r " .. FormatMoney(currentCost))
    else
        priceText:SetText("|cffffd100Крафт:|r |cffbbbbbbнет данных|r")
    end
end)

