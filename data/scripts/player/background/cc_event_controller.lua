package.path = package.path .. ";data/scripts/lib/?.lua"

-- Helper to fetch the highest local War Heat from the sector's factions
local function getSectorWarHeat()
    local sector = Sector()
    local factions = {sector:getPresentFactions()}
    local heat = 0

    for _, f in pairs(factions) do
        local faction = Faction(f)
        if faction and faction.isAIFaction then
            local success, CosmicWarBridge = pcall(require, "cosmicwarbridge")
            if success and CosmicWarBridge and CosmicWarBridge.getWarHeat then
                local rawHeat = CosmicWarBridge.getWarHeat(faction.index) or 0
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
    if #sector:getEntitiesByComponent(ComponentType.Station) > 0 then return end

    -- Prevent infinite farming: ensure narrative events only spawn once per sector
    if sector:getValue("cc_event_spawned") then return end

    local heat = getSectorWarHeat()

    -- 25% chance to spawn Graveyard if Heat > 80
    if heat > 80 and random():getInt(1, 100) <= 25 then
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cw_derelictgraveyard.lua")
    -- 25% chance to spawn Refugees if Heat > 40
    elseif heat > 40 and random():getInt(1, 100) <= 25 then
        sector:setValue("cc_event_spawned", true)
        sector:addScriptOnce("events/cw_refugeeconvoy.lua")
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
                -- If we are in the "Inner Area" (<= 15 distance from home), 15% chance to find a Monument
                if dist <= 15 and random():getInt(1, 100) <= 15 then
                    sector:setValue("cc_event_spawned", true)
                    sector:addScriptOnce("events/cc_spawnmonument.lua")
                end
            end
        end
    end
end

function initialize()
    -- Listen to the global sector jump callback
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end