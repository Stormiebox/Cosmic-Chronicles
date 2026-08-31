package.path = package.path .. ";data/scripts/lib/?.lua"
include("randomext")

-- Load APIs
local CosmicVaultNews = include("cosmicvaultnews")
local cw_success = true; include("cosmicwarbridge")
local FactionEradicationUtility = include("factioneradicationutility")
local cv_economy = include("cosmicvaulteconomy")

-- namespace CosmicChroniclesNewsGenerator
CosmicChroniclesNewsGenerator = {}

function CosmicChroniclesNewsGenerator.getUpdateInterval()
    -- Generate a new piece of news every 15 minutes of server uptime
    return 15 * 60
end

function CosmicChroniclesNewsGenerator.initialize()
    if not onServer() then return end
    Galaxy():registerCallback("onBehemothAttackStart", "onBehemothAttackStart")
end

-- Tags an article as "breaking" (the news board's own client-side UI reads this flag to
-- show a dedicated banner and prefix the headline) and immediately alerts every online
-- player in chat, since a galaxy-shaking event shouldn't wait for someone to remember to
-- open the News tab. CosmicVaultNews.publishArticle only validates title/content/category
-- and preserves any other fields verbatim, so this extra field is safe to add without
-- touching the shared Cosmic Vault API.
local function publishBreaking(article)
    if not CosmicVaultNews then return end
    article.breaking = true
    CosmicVaultNews.publishArticle(article)

    local server = Server()
    if not server then return end
    for _, player in pairs({server:getOnlinePlayers()}) do
        if player then
            player:sendChatMessage("Galactic News Network"%_T, 3, "BREAKING: %1%"%_T, article.title)
        end
    end
end

function CosmicChroniclesNewsGenerator.onBehemothAttackStart(quadrant, x, y)
    if not CosmicVaultNews then return end
    local quadName = "Unknown"
    if quadrant == 1 then quadName = "North"
    elseif quadrant == 2 then quadName = "East"
    elseif quadrant == 3 then quadName = "South"
    elseif quadrant == 4 then quadName = "West" end

    publishBreaking({
        title = "BEHEMOTH INCURSION DETECTED",
        content = "Warning! A catastrophic spatial anomaly has been detected! The Behemoth of the " .. tostring(quadName) .. " has dropped out of hyperspace and is currently assaulting sector [" .. tostring(x) .. ":" .. tostring(y) .. "]. All available captains are urged to defend the sector immediately!",
        category = "Galactic Threat"
    })
end

local reportedBosses = {}

-- factionIndex -> last-known name, for any AI faction seen active. Used to detect the
-- active -> eradicated transition (see checkFactionEradications) and to still have a name
-- to report with once Faction(index) itself starts returning nil for the fallen empire.
local knownActiveFactions = {}

function CosmicChroniclesNewsGenerator.updateServer(timeStep)
    if not CosmicVaultNews then return end -- Vault News API not available

    local rand = random():getInt(1, 100)

    -- Check for Boss Defeats (Highest priority, but only once per boss)
    if CosmicChroniclesNewsGenerator.checkBossDefeats() then return end

    -- Check for freshly eradicated empires (also high priority, but rare and one-shot per faction)
    if CosmicChroniclesNewsGenerator.checkFactionEradications() then return end

    if rand <= 25 and cw_success then
        CosmicChroniclesNewsGenerator.generateWarNews()
    elseif rand <= 50 then
        CosmicChroniclesNewsGenerator.generateEconomyNews()
    elseif rand <= 75 then
        CosmicChroniclesNewsGenerator.generateCaptainNews()
    else
        CosmicChroniclesNewsGenerator.generateDiscoveryNews()
    end
end

function CosmicChroniclesNewsGenerator.checkBossDefeats()
    local server = Server()

    local function publish(id, title, content)
        if not reportedBosses[id] then
            reportedBosses[id] = true
            publishBreaking({ title = title, content = content, category = "Galactic Milestone" })
            return true
        end
        return false
    end

    if server:getValue("swoks_beaten") then
        if publish("swoks", "Pirate Warlord Swoks Eliminated", "Independent bounty hunters have confirmed the destruction of the infamous pirate lord Swoks. The outer rim breathes a sigh of relief as his blockades dissolve.") then return true end
    end

    if server:getValue("big_ai_kill_counter") and server:getValue("big_ai_kill_counter") > 0 then
        if publish("big_ai", "Rogue AI Core Shattered", "A massive spatial anomaly has collapsed near the inner rim. Reports confirm that the rogue Artificial Intelligence construct threatening navigational arrays has been completely neutralized.") then return true end
    end

    if server:getValue("last_killed_laser_boss") then
        if publish("laser_boss", "Project Beta Neutralized", "A massive experimental laser dreadnought known as 'Project Beta' has been destroyed. Authorities are investigating its origins.") then return true end
    end

    -- For player-specific bosses, we iterate over online players
    for _, player in pairs({server:getOnlinePlayers()}) do
        if player:getValue("last_killed_scientist") then
            if publish("scientist", "M.A.D. Science Lab Destroyed", "A secretive mobile laboratory conducting deeply unethical experiments has been eradicated. Authorities caution scavengers against approaching the irradiated wreckage.") then return true end
        end

        if player:getValue("last_killed_bottan") then
            if publish("bottan", "Bottan's Smuggling Ring Busted!", "The infamous smuggler Bottan has finally been brought to justice. Faction security forces report a massive drop in black market shipments.") then return true end
        end

        if player:getValue("last_killed_the4") then
            if publish("the4", "The Brotherhood Shattered", "The elusive cult known as 'The Brotherhood', or 'The 4', has been decimated. Their mysterious artifact has been recovered.") then return true end
        end

        if player:getValue("wormhole_guardian_destroyed") then
            if publish("guardian", "The Core is Open!", "A shockwave of unimaginable scale has echoed across the galaxy. The Xsotan Wormhole Guardian blockading the galactic core has fallen! A new era of exploration and danger has begun.") then return true end
        end
    end

    return false
end

-- Detects the moment an AI faction transitions from active to eradicated (per
-- FactionEradicationUtility, the same shared check every generator here already uses to
-- filter its own faction pool) and reports it as Breaking News. Only reports a transition
-- actually observed by this tracker -- a faction already gone before it was ever seen active
-- is not retroactively announced.
function CosmicChroniclesNewsGenerator.checkFactionEradications()
    local server = Server()
    local factionStr = server:getValue("factions")
    if type(factionStr) ~= "string" or factionStr == "" then return false end
    if not FactionEradicationUtility or not FactionEradicationUtility.isFactionEradicated then return false end

    for id in string.gmatch(factionStr, "([^,]+)") do
        local idx = tonumber(id)
        if idx then
            local isEradicated = FactionEradicationUtility.isFactionEradicated(idx)

            if isEradicated then
                local knownName = knownActiveFactions[idx]
                if knownName then
                    knownActiveFactions[idx] = nil
                    publishBreaking({
                        title = "EMPIRE HAS FALLEN: " .. tostring(knownName),
                        content = "Galactic Archive services confirm the complete collapse of " .. tostring(knownName) .. ". Every remaining foothold, station, and vessel belonging to the empire has been lost. Surviving citizens are reportedly fleeing to neighboring territories, while opportunists move to claim the wreckage of their infrastructure.",
                        category = "Galactic Milestone"
                    })
                    return true
                end
            else
                local f = Faction(idx)
                if f and not f.isPlayer and not f.isAlliance then
                    knownActiveFactions[idx] = f.name
                end
            end
        end
    end

    return false
end

function CosmicChroniclesNewsGenerator.generateWarNews()
    local factions = {}
    local factionStr = Server():getValue("factions")
    if type(factionStr) == "string" and factionStr ~= "" then
        for id in string.gmatch(factionStr, "([^,]+)") do
            local f = Faction(tonumber(id))
            if f then table.insert(factions, f) end
        end
    end
    local validFactions = {}
    for _, f in pairs(factions) do
        if f and not f.isPlayer and not f.isAlliance then
            local isEradicated = false
            if FactionEradicationUtility and FactionEradicationUtility.isFactionEradicated then
                isEradicated = FactionEradicationUtility.isFactionEradicated(f.index)
            end
            if not isEradicated then
                table.insert(validFactions, f)
            end
        end
    end
    if #validFactions == 0 then return end
    local faction = validFactions[random():getInt(1, #validFactions)]

    local heat = 0
    if CosmicWarBridge and CosmicWarBridge.computeWarHeatForFaction then
        heat = CosmicWarBridge.computeWarHeatForFaction(faction)
    end

    local hx, hy = faction:getHomeSectorCoordinates()
    if not hx or not hy then return end -- Prevent crash if faction has no home sector

    if heat > 0.5 then
        -- Generate exact coordinates for the bounty
        local ox = hx + random():getInt(-15, 15)
        local oy = hy + random():getInt(-15, 15)
        
        -- Store the bounty in the global server value (max 10 active)
        local activeBounties = Server():getValue("cc_active_bounties") or ""
        local bountyList = {}
        for b in string.gmatch(activeBounties, "([^;]+)") do
            table.insert(bountyList, b)
        end
        table.insert(bountyList, tostring(ox)..":"..tostring(oy))
        while #bountyList > 10 do table.remove(bountyList, 1) end
        Server():setValue("cc_active_bounties", table.concat(bountyList, ";"))

        CosmicVaultNews.publishArticle({
            title = "MOST WANTED: " .. tostring(faction.name) .. " Issues High-Value Bounty",
            content = "Due to extreme hostiles operating in their territory, the " .. tostring(faction.name) .. " military has designated a notorious pirate dreadnought as a Tier 1 Threat. Intelligence places the target precisely at sector [" .. tostring(ox) .. ":" .. tostring(oy) .. "].\n\nAll independent mercenaries are cleared to engage. A massive bounty has been authorized for its destruction.",
            category = "Bounty Board"
        })
    else
        local ox = hx + random():getInt(-15, 15)
        local oy = hy + random():getInt(-15, 15)
        local sectorStr = " near sector [" .. ox .. ":" .. oy .. "]"
        CosmicVaultNews.publishArticle({
            title = "Territorial Shift in " .. tostring(faction.name) .. " Space",
            content = "Military outposts report that " .. tostring(faction.name) .. " has successfully pushed the frontline further into enemy space following a decisive victory" .. sectorStr .. ".\n\nScavenger vessels are already moving in to clean up the wreckage of the destroyed staging grounds.",
            category = "Conflict"
        })
    end
end

function CosmicChroniclesNewsGenerator.generateEconomyNews()
    local factions = {}
    local factionStr = Server():getValue("factions")
    if type(factionStr) == "string" and factionStr ~= "" then
        for id in string.gmatch(factionStr, "([^,]+)") do
            local f = Faction(tonumber(id))
            if f then table.insert(factions, f) end
        end
    end
    local validFactions = {}
    for _, f in pairs(factions) do
        if f and not f.isPlayer and not f.isAlliance then
            local isEradicated = false
            if FactionEradicationUtility and FactionEradicationUtility.isFactionEradicated then
                isEradicated = FactionEradicationUtility.isFactionEradicated(f.index)
            end
            if not isEradicated then
                table.insert(validFactions, f)
            end
        end
    end
    if #validFactions == 0 then return end
    local faction = validFactions[random():getInt(1, #validFactions)]

    if random():test(0.5) then
        CosmicVaultNews.publishArticle({
            title = "Trade Crisis: " .. tostring(faction.name) .. " Faces Severe Shortages",
            content = "A recent string of pirate embargoes has plunged " .. tostring(faction.name) .. " into a severe resource drought. Reports indicate critical shortages of Medical Supplies and Processors.\n\nPrices have skyrocketed. Independent merchants and smugglers are advised to exploit the markup while the crisis lasts.",
            category = "Economy"
        })
        if cv_economy and cv_economy.addFamineScore then
            cv_economy.addFamineScore(faction.index, 25)
        end
    else
        CosmicVaultNews.publishArticle({
            title = "Market Boom: " .. tostring(faction.name) .. " Tech Sector Surges",
            content = "Stock exchanges across " .. tostring(faction.name) .. " space have reported record highs today. A sudden surplus in industrial goods has driven manufacturing costs down, resulting in massive profits for local mega-corporations.",
            category = "Economy"
        })
        if cv_economy and cv_economy.addFamineScore then
            cv_economy.addFamineScore(faction.index, -20)
        end
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
                if captain.primaryClass == 6 then capClass = "Explorer"
                elseif captain.primaryClass == 2 then capClass = "Smuggler"
                elseif captain.primaryClass == 3 then capClass = "Merchant"
                elseif captain.primaryClass == 4 then capClass = "Miner"
                elseif captain.primaryClass == 5 then capClass = "Scavenger"
                end
            end
        end
    end

    CosmicVaultNews.publishArticle({
        title = "Galactic Spotlight: The Exploits of " .. tostring(playerName),
        content = "Famed " .. capClass .. " captain, " .. tostring(playerName) .. ", has recently made headlines across the coreward sectors after successfully completing a massive and highly dangerous operation.\n\nLocal authorities have praised their efforts, and their reputation continues to grow among the stars.",
        category = "Captain Feats"
    })
end

local discoveryHeadlines = {
    {
        title = "Uncharted Signal Detected Near %s",
        content = "Long-range sensor arrays have picked up an unidentified transmission originating from deep space near %s. Exploration guilds are already dispatching scouts to investigate, though officials warn the signal's origin remains unconfirmed."
    },
    {
        title = "Ancient Ruins Cataloged Near %s",
        content = "A survey team operating near %s has cataloged the remains of a long-abandoned structure, predating known galactic civilization by an unknown margin. Archaeological interest in the region has surged overnight."
    },
    {
        title = "Derelict Fleet Located Near %s",
        content = "Salvage crews report locating the wreckage of a sizable derelict fleet drifting near %s. The cause of its destruction is unknown, and independent salvagers are moving in quickly to stake their claims."
    },
    {
        title = "Rare Stellar Phenomenon Observed Near %s",
        content = "Astronomers have confirmed an exceptionally rare stellar phenomenon unfolding near %s. Sightseeing vessels are already reporting heavy traffic in the area, with researchers eager to study the event before it fades."
    },
}

-- Flavor/ambient discovery reporting, matching the established low-mechanical-impact pattern
-- already used by Captain Feats and Territorial Shift -- no gameplay effect, pure atmosphere.
function CosmicChroniclesNewsGenerator.generateDiscoveryNews()
    local factions = {}
    local factionStr = Server():getValue("factions")
    if type(factionStr) == "string" and factionStr ~= "" then
        for id in string.gmatch(factionStr, "([^,]+)") do
            local f = Faction(tonumber(id))
            if f then table.insert(factions, f) end
        end
    end
    local validFactions = {}
    for _, f in pairs(factions) do
        if f and not f.isPlayer and not f.isAlliance then
            local isEradicated = false
            if FactionEradicationUtility and FactionEradicationUtility.isFactionEradicated then
                isEradicated = FactionEradicationUtility.isFactionEradicated(f.index)
            end
            if not isEradicated then
                table.insert(validFactions, f)
            end
        end
    end
    if #validFactions == 0 then return end
    local faction = validFactions[random():getInt(1, #validFactions)]

    local hx, hy = faction:getHomeSectorCoordinates()
    if not hx or not hy then return end

    local ox = hx + random():getInt(-20, 20)
    local oy = hy + random():getInt(-20, 20)
    local sectorLabel = string.format("sector [%d:%d]", ox, oy)

    local entry = discoveryHeadlines[random():getInt(1, #discoveryHeadlines)]

    CosmicVaultNews.publishArticle({
        title = string.format(entry.title, sectorLabel),
        content = string.format(entry.content, sectorLabel),
        category = "Discovery"
    })
end

function CosmicChroniclesNewsGenerator.secure()
    return {
        reportedBosses = reportedBosses,
        knownActiveFactions = knownActiveFactions
    }
end

function CosmicChroniclesNewsGenerator.restore(data)
    reportedBosses = data.reportedBosses or {}
    knownActiveFactions = data.knownActiveFactions or {}
end






