package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CosmicChroniclesStockMarket = {}

function CosmicChroniclesStockMarket.initialize()
    if onServer() then
        -- Run the stock market check every 20 minutes (Galactic Turn)
        Timer():create("simulateStockMarket", 1200)
    end
end

function CosmicChroniclesStockMarket.simulateStockMarket()
    local factions = {Galaxy():getFactions()}
    if #factions == 0 then return end
    
    local targetFaction = factions[random():getInt(1, #factions)]
    if targetFaction.isPlayer or targetFaction.isAlliance then return end
    if targetFaction.isAIFaction == false then return end
    
    local isBoom = random():getFloat() > 0.5
    local article = {}
    
    if isBoom then
        article.title = targetFaction.name .. " Economic Boom"
        article.content = "Massive industrial surpluses are crashing local commodity prices across " .. targetFaction.name .. " territory. Traders are flocking to take advantage of the dirt-cheap supply."
        article.category = "Economy"
    else
        article.title = targetFaction.name .. " Supply Chain Collapse"
        article.content = "Critical supply chain failures have caused a massive shortage of high-tech and medical goods in " .. targetFaction.name .. " sectors. Demand prices are skyrocketing."
        article.category = "Economy"
    end
    
    -- Send to news board
    Server():sendCallback("onCCNewsPublishArticle", article)
end

return CosmicChroniclesStockMarket
