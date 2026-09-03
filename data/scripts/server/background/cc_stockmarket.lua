package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local FactionEradicationUtility = include("factioneradicationutility")
local cv_economy = include("cosmicvaulteconomy")
local cv_news = include("cosmicvaultnews")

local CosmicChroniclesStockMarket = {}

function CosmicChroniclesStockMarket.initialize()
    -- Nothing needed here
end

function getUpdateInterval()
    return 1200 -- Run the stock market check every 20 minutes (Galactic Turn)
end

function updateServer(timeStep)
    CosmicChroniclesStockMarket.simulateStockMarket()
end

function CosmicChroniclesStockMarket.simulateStockMarket()
    local factions = {}
    local factionStr = Server():getValue("factions")
    if type(factionStr) == "string" and factionStr ~= "" then
        for id in string.gmatch(factionStr, "([^,]+)") do
            local f = Faction(tonumber(id))
            if f then table.insert(factions, f) end
        end
    end
    if #factions == 0 then return end

    local targetFaction
    -- Try to find a valid faction, max 20 attempts
    for i = 1, 20 do
        local f = factions[random():getInt(1, #factions)]
        if f and not f.isPlayer and not f.isAlliance and f.isAIFaction then
            if not FactionEradicationUtility.isFactionEradicated(f.index) then
                targetFaction = f
                break
            end
        end
    end

    if not targetFaction then return end

    local isBoom = random():getFloat() > 0.5
    local article = {}

    if isBoom then
        article.title = tostring(targetFaction.name) .. " Economic Boom"
        article.content = "Massive industrial surpluses are crashing local commodity prices across " .. tostring(targetFaction.name) .. " territory. Traders are flocking to take advantage of the dirt-cheap supply."
        article.category = "Economy"
        if cv_economy and cv_economy.addFamineScore then
            cv_economy.addFamineScore(targetFaction.index, -25)
        end
    else
        article.title = tostring(targetFaction.name) .. " Supply Chain Collapse"
        article.content = "Critical supply chain failures have caused a massive shortage of high-tech and medical goods in " .. tostring(targetFaction.name) .. " sectors. Demand prices are skyrocketing."
        article.category = "Economy"
        if cv_economy and cv_economy.addFamineScore then
            cv_economy.addFamineScore(targetFaction.index, 35)
        end
    end

    -- Send to news board
    if cv_news and cv_news.publishArticle then
        cv_news.publishArticle(article)
    else
        Server():sendCallback("onCCNewsPublishArticle", article)
    end
end

function initialize(...)
    if CosmicChroniclesStockMarket.initialize then return CosmicChroniclesStockMarket.initialize(...) end
end
