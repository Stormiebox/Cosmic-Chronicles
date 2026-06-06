package.path = package.path .. ";data/scripts/lib/?.lua"
include("randomext")

-- Load APIs
local cv_success = pcall(include, "cosmicvaultnews")
local cw_success = pcall(include, "cosmicwarbridge")

-- namespace CosmicChroniclesNewsGenerator
CosmicChroniclesNewsGenerator = {}

function CosmicChroniclesNewsGenerator.getUpdateInterval()
    -- Generate a new piece of news every 15 minutes of server uptime
    return 15 * 60
end

function CosmicChroniclesNewsGenerator.initialize()
    if not onServer() then return end
end

local reportedBosses = {}

function CosmicChroniclesNewsGenerator.updateServer(timeStep)
    if not cv_success then return end -- Vault News API not available
    
    local rand = random():getInt(1, 100)
    
    -- Check for Boss Defeats (Highest priority, but only once per boss)
    if CosmicChroniclesNewsGenerator.checkBossDefeats() then return end
    
    if rand <= 33 and cw_success then
        CosmicChroniclesNewsGenerator.generateWarNews()
    elseif rand <= 66 then
        CosmicChroniclesNewsGenerator.generateEconomyNews()
    else
        CosmicChroniclesNewsGenerator.generateCaptainNews()
    end
end

function CosmicChroniclesNewsGenerator.checkBossDefeats()
    local bosses = {
        { id = "swoks_defeated", title = "Pirate Warlord Swoks Eliminated", content = "Independent bounty hunters have confirmed the destruction of the infamous pirate lord Swoks. The outer rim breathes a sigh of relief as his blockades dissolve." },
        { id = "ai_destroyed", title = "Rogue AI Core Shattered", content = "A massive spatial anomaly has collapsed near the inner rim. Reports confirm that the rogue Artificial Intelligence construct threatening navigational arrays has been completely neutralized." },
        { id = "mad_science_lab_destroyed", title = "M.A.D. Science Lab Destroyed", content = "A highly dangerous, unauthorized weapons research facility known as the M.A.D. Science Lab has been eradicated. Authorities caution scavengers against approaching the irradiated wreckage." },
        { id = "guardian_destroyed", title = "The Core is Open!", content = "A shockwave of unimaginable scale has echoed across the galaxy. The Xsotan Wormhole Guardian blockading the galactic core has fallen! A new era of exploration and danger has begun." }
    }
    
    for _, boss in pairs(bosses) do
        if Server():getValue(boss.id) and not reportedBosses[boss.id] then
            reportedBosses[boss.id] = true
            CosmicVaultNews.publishArticle({ title = boss.title, content = boss.content, category = "Galactic Milestone" })
            return true
        end
    end
    return false
end

function CosmicChroniclesNewsGenerator.generateWarNews()
    local factions = {Galaxy():getFactions()}
    if #factions == 0 then return end
    local faction = factions[random():getInt(1, #factions)]
    
    local heat = 0
    if CosmicWarBridge and CosmicWarBridge.computeWarHeatForFaction then
        heat = CosmicWarBridge.computeWarHeatForFaction(faction)
    end
    
    local hx, hy = faction:getHomeSectorCoordinates()
    local sectorStr = ""
    if hx and hy then
        local ox = hx + random():getInt(-15, 15)
        local oy = hy + random():getInt(-15, 15)
        sectorStr = " near sector [" .. ox .. ":" .. oy .. "]"
    end
    
    if heat > 0.5 then
        CosmicVaultNews.publishArticle({
            title = "MOST WANTED: " .. faction.name .. " Issues High-Value Bounty",
            content = "Due to extreme hostiles operating in their territory, the " .. faction.name .. " military has designated a notorious pirate dreadnought as a Tier 1 Threat" .. sectorStr .. ".\n\nAll independent mercenaries are cleared to engage. A massive bounty has been authorized for its destruction.",
            category = "Bounty Board"
        })
    else
        CosmicVaultNews.publishArticle({
            title = "Territorial Shift in " .. faction.name .. " Space",
            content = "Military outposts report that " .. faction.name .. " has successfully pushed the frontline further into enemy space following a decisive victory" .. sectorStr .. ".\n\nScavenger vessels are already moving in to clean up the wreckage of the destroyed staging grounds.",
            category = "Conflict"
        })
    end
end

function CosmicChroniclesNewsGenerator.generateEconomyNews()
    local factions = {Galaxy():getFactions()}
    if #factions == 0 then return end
    local faction = factions[random():getInt(1, #factions)]
    
    if random():test(0.5) then
        CosmicVaultNews.publishArticle({
            title = "Trade Crisis: " .. faction.name .. " Faces Severe Shortages",
            content = "A recent string of pirate embargoes has plunged " .. faction.name .. " into a severe resource drought. Reports indicate critical shortages of Medical Supplies and Processors.\n\nPrices have skyrocketed. Independent merchants and smugglers are advised to exploit the markup while the crisis lasts.",
            category = "Economy"
        })
    else
        CosmicVaultNews.publishArticle({
            title = "Market Boom: " .. faction.name .. " Tech Sector Surges",
            content = "Stock exchanges across " .. faction.name .. " space have reported record highs today. A sudden surplus in industrial goods has driven manufacturing costs down, resulting in massive profits for local mega-corporations.",
            category = "Economy"
        })
    end
end

function CosmicChroniclesNewsGenerator.generateCaptainNews()
    local players = {Server():getOnlinePlayers()}
    local playerName = "an Independent Captain"
    local capClass = "Commander"
    
    if #players > 0 then
        local p = players[random():getInt(1, #players)]
        playerName = p.name
        if p.craft then
            local captain = p.craft:getCaptain()
            if captain then
                if captain.primaryClass == 1 then capClass = "Explorer"
                elseif captain.primaryClass == 2 then capClass = "Smuggler"
                elseif captain.primaryClass == 3 then capClass = "Merchant"
                elseif captain.primaryClass == 4 then capClass = "Miner"
                elseif captain.primaryClass == 5 then capClass = "Scavenger"
                end
            end
        end
    end
    
    CosmicVaultNews.publishArticle({
        title = "Galactic Spotlight: The Exploits of " .. playerName,
        content = "Famed " .. capClass .. " captain, " .. playerName .. ", has recently made headlines across the coreward sectors after successfully completing a massive and highly dangerous operation.\n\nLocal authorities have praised their efforts, and their reputation continues to grow among the stars.",
        category = "Captain Feats"
    })
end
