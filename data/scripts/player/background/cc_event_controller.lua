package.path = package.path .. ";data/scripts/lib/?.lua"

include("randomext")
local cw_success = pcall(include, "cosmicwarbridge")

-- Helper to fetch the highest local War Heat from the sector's factions
local function getSectorWarHeat(x, y)
    local sector = Sector()
    local factionIndices = {sector:getPresentFactions()}
    
    local nearestFaction = Galaxy():getNearestFaction(x, y)
    if nearestFaction then
        table.insert(factionIndices, nearestFaction.index)
    end
    
    local heat = 0

    for _, f in pairs(factionIndices) do
        local faction = Faction(f)
        if faction and faction.isAIFaction then
            if cw_success and CosmicWarBridge and CosmicWarBridge.getFactionWarHeat then
                local rawHeat = CosmicWarBridge.getFactionWarHeat(faction.index) or 0
                heat = math.max(heat, math.floor(rawHeat * 100))
            elseif faction:getValue("cw_enabled") then
                local rawHeat = faction:getValue("cw_war_heat") or 0
                heat = math.max(heat, math.floor(rawHeat * 100))
            end
        end
    end
    return heat
end

function onSectorEntered(playerIndex, x, y, sectorChangeType)
    if not onServer() then return end
    
    if sectorChangeType ~= SectorChangeType.Jump then return end

    local sector = Sector()
    -- Only trigger these specific narrative events in empty or deep space sectors
    if #{sector:getEntitiesByType(EntityType.Station)} > 0 then return end

    -- Prevent infinite farming: ensure narrative events only spawn once per sector
    if sector:getValue("cc_event_spawned") then return end

    local coordStr = tostring(x)..":"..tostring(y)
    local activeBounties = Server():getValue("cc_active_bounties") or ""
    if string.find(activeBounties, coordStr) then
        -- Remove from list
        local newList = {}
        for b in string.gmatch(activeBounties, "([^;]+)") do
            if b ~= coordStr then table.insert(newList, b) end
        end
        Server():setValue("cc_active_bounties", table.concat(newList, ";"))
        
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cc_bounty_ambush.lua")
        return
    end
    
    local activeStashes = Server():getValue("cc_hidden_stashes") or ""
    if string.find(activeStashes, coordStr) then
        local newList = {}
        for s in string.gmatch(activeStashes, "([^;]+)") do
            if s ~= coordStr then table.insert(newList, s) end
        end
        Server():setValue("cc_hidden_stashes", table.concat(newList, ";"))
        
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cc_hiddenstash.lua")
        return
    end

    local heat = getSectorWarHeat(x, y)

    -- 10% chance to spawn Graveyard if Heat > 40
    if heat > 40 and random():getInt(1, 100) <= 10 then
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cc_derelictgraveyard.lua")
    -- 10% chance to spawn Refugees if Heat > 40
    elseif heat > 40 and random():getInt(1, 100) <= 10 then
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cc_refugeeconvoy.lua")
    else
        -- Determine if we are deep inside AI territory
        local controllingFaction = Galaxy():getNearestFaction(x, y)

        if controllingFaction and controllingFaction.isAIFaction then
            local hx, hy = controllingFaction:getHomeSectorCoordinates()
            if hx and hy then
                local dist = math.sqrt((x - hx)^2 + (y - hy)^2)
                -- If we are in the "Inner Area" (<= 15 distance from home), 10% chance to find a Monument
                if dist <= 15 and random():getInt(1, 100) <= 10 then
                    sector:setValue("cc_event_spawned", true)
                    sector:addScriptOnce("events/cc_spawnmonument.lua")
                    return
                end
            end
        end

        -- v3.0.0: New Deep Space Events
        -- Tuned down significantly to keep empty sectors mostly empty
        local coreDist = math.sqrt(x*x + y*y)
        local roll = random():getInt(1, 100)

        if coreDist <= 150 and roll <= 5 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_ancientdatacache.lua")
        elseif roll > 5 and roll <= 8 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_rogueaiprobe.lua")
        elseif roll > 8 and roll <= 11 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_ghostship.lua")
        elseif roll > 11 and roll <= 14 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_diplomatescort.lua")
        end
    end
end

function initialize()
    -- Listen to the global sector jump callback
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end