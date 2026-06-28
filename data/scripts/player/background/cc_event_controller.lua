package.path = package.path .. ";data/scripts/lib/?.lua"

include("randomext")
local cw_success = true; include("cosmicwarbridge")

-- Helper to fetch the highest local War Heat from the sector's factions
local function getSectorWarHeat()
    local sector = Sector()
    local factions = {sector:getPresentFactions()}
    local heat = 0

    for _, f in pairs(factions) do
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

    local sector = Sector()
    -- Only trigger these specific narrative events in empty or deep space sectors
    if #{sector:getEntitiesByType(EntityType.Station)} > 0 then return end

    -- Prevent infinite farming: ensure narrative events only spawn once per sector
    if sector:getValue("cc_event_spawned") then return end

    local heat = getSectorWarHeat()

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
        local controllingFaction = nil
        for _, f in pairs({sector:getPresentFactions()}) do
            local faction = Faction(f)
            if faction and faction.isAIFaction then
                controllingFaction = faction
                break
            end
        end

        if controllingFaction then
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
        local coreDist = math.sqrt(x*x + y*y)
        local roll = random():getInt(1, 100)

        if coreDist <= 150 and roll <= 10 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_ancientdatacache.lua")
        elseif roll > 10 and roll <= 18 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_rogueaiprobe.lua")
        elseif roll > 18 and roll <= 26 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_ghostship.lua")
        elseif roll > 26 and roll <= 34 then
            sector:setValue("cc_event_spawned", true)
            sector:addScriptOnce("events/cc_diplomatescort.lua")
        end
    end
end

function initialize()
    -- Listen to the global sector jump callback
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end