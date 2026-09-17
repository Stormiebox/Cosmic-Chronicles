package.path = package.path .. ";data/scripts/lib/?.lua"

local Territory = include("cosmicvaultterritory")

-- namespace ChronicleSectorObserver
ChronicleSectorObserver = {}
local self = ChronicleSectorObserver
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local MATERIALIZER = "data/scripts/sector/cc_event_materializer.lua"
local RUMORMONGER = "data/scripts/entity/cosmicchronicles_rumormonger.lua"
local RESEARCH_EXCHANGE = "data/scripts/entity/cc_research_exchange.lua"
local BEHEMOTH_TRACKER = "data/scripts/entity/cc_behemoth_tracker.lua"
local CHATTER_INTERVAL = 45
self.pendingDestroyedEvents = {}
self.pendingObservations = {}

local function attachStation(entity)
    if not valid(entity) or not entity.isStation then return end
    entity:addScriptOnce(RUMORMONGER)
    if entity:hasScript("data/scripts/entity/merchants/researchstation.lua") then
        entity:addScriptOnce(RESEARCH_EXCHANGE)
    end
end

local function attachEntity(entity)
    if not valid(entity) then return end
    if entity.isStation then attachStation(entity) end
    if entity:getValue("behemoth_boss") == true then entity:addScriptOnce(BEHEMOTH_TRACKER) end
end

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function observeLegacy(x, y)
    local sector = Sector()
    local lootTriggered = #{sector:getEntitiesByScriptValue("cc_loot_triggered", true)} > 0
    local evidence = {
        eventSpawned = sector:getValue("cc_event_spawned") == true,
        bountyBossSpawned = sector:getValue("cc_bounty_boss_spawned") == true,
        lootTriggered = lootTriggered,
    }
    if evidence.eventSpawned or evidence.bountyBossSpawned or evidence.lootTriggered then
        invokeCoordinator("recordLoadedSectorLegacyEvidence", x, y, evidence)
        return true
    end
    return false
end

function ChronicleSectorObserver.initialize()
    if not onServer() then return end
    Sector():registerCallback("onEntityCreated", "onEntityCreated")
    Sector():registerCallback("onScriptAdded", "onScriptAdded")
    Sector():registerCallback("onDestroyed", "onDestroyed")
    local stations = {Sector():getEntitiesByType(EntityType.Station)}
    for index = 1, math.min(#stations, 64) do attachStation(stations[index]) end
    local behemoths = {Sector():getEntitiesByScriptValue("behemoth_boss", true)}
    for index = 1, math.min(#behemoths, 4) do attachEntity(behemoths[index]) end
end

function ChronicleSectorObserver.getUpdateInterval()
    return 5
end

function ChronicleSectorObserver.updateServer(timeStep)
    local sector = Sector()
    local currentTime = Server().unpausedRuntime
    local behemoth = sector:getEntitiesByScriptValue("behemoth_boss", true)
    if behemoth and valid(behemoth) and not behemoth:hasScript(BEHEMOTH_TRACKER) then
        behemoth:addScriptOnce(BEHEMOTH_TRACKER)
    end
    for eventId, pending in pairs(self.pendingDestroyedEvents) do
        if currentTime >= pending.checkAt then
            self.pendingDestroyedEvents[eventId] = nil
            local remaining = {sector:getEntitiesByScriptValue("cc_event_id", eventId)}
            if #remaining == 0 then
                local event = invokeCoordinator("getEvent", eventId)
                if event and event.state == "active" then
                    local summary = pending.eventType == "hidden_stash"
                        and "The concealed resource cache was exhausted."
                        or "The Chronicle event entity was destroyed before its interaction completed."
                    local resolving = invokeCoordinator("requestEventTransition", "event_resolver",
                        eventId, event.revision, "resolving",
                        {outcome = {kind = "entity_destroyed", summary = summary}})
                    if resolving then
                        invokeCoordinator("requestEventTransition", "event_resolver", eventId,
                            resolving.revision, pending.eventType == "hidden_stash"
                                and "succeeded" or "failed_permanent",
                            {outcome = {kind = "entity_destroyed", summary = summary}})
                    end
                end
            end
        end
    end
    for observationId, observation in pairs(self.pendingObservations) do
        self.pendingObservations[observationId] = nil
        invokeCoordinator("publishObservedEvent", "sector_observer", observation)
        break
    end
    if currentTime < (tonumber(sector:getValue("cc_chatter_v2_next")) or 0) then return end
    local players = {sector:getPlayers()}
    if #players == 0 then return end
    local stations = {sector:getEntitiesByType(EntityType.Station)}
    local candidates = {}
    for index = 1, math.min(#stations, 64) do
        local station = stations[index]
        if valid(station) and station:hasScript(RUMORMONGER) then
            candidates[#candidates + 1] = station
        end
    end
    if #candidates == 0 then return end
    sector:setValue("cc_chatter_v2_next", currentTime + CHATTER_INTERVAL)
    local station = candidates[random():getInt(1, #candidates)]
    local targetPlayer = players[random():getInt(1, #players)]
    local status, line = station:invokeFunction(RUMORMONGER, "getAmbientLine",
        targetPlayer.index)
    if status == 0 and type(line) == "string" then
        sector:broadcastChatMessage(station, ChatMessageType.Chatter, line)
    end
end

function ChronicleSectorObserver.onEntityCreated(entityId)
    attachEntity(Entity(entityId))
end

function ChronicleSectorObserver.onScriptAdded(entityId, scriptIndex, scriptPath)
    attachEntity(Entity(entityId))
end

function ChronicleSectorObserver.onDestroyed(entityId, destroyerId)
    local entity = Entity(entityId)
    if not valid(entity) then return end
    if entity.isStation then
        local x, y = Sector():getCoordinates()
        local observation = {
            kind = "station_destroyed", identity = "station:" .. tostring(entityId),
            eventType = "chronicles.observation.station.destroyed", topic = "threat",
            category = "Breaking News", severity = "critical", breaking = true,
            title = "Station Destroyed",
            content = "A station was destroyed in a verified sector combat incident.",
            location = {x = x, y = y}, provenance = {recordType = "sector_callback",
                recordId = tostring(entityId), sourceRevision = 0,
                sourceState = "destroyed", destroyerId = tostring(destroyerId)},
        }
        self.pendingObservations[observation.identity] = observation
    end
    local eventId = entity:getValue("cc_event_id")
    local eventType = entity:getValue("cc_event_type")
    if type(eventId) == "string" and type(eventType) == "string"
            and eventType ~= "bounty_ambush" and eventType ~= "rogue_ai_probe" then
        self.pendingDestroyedEvents[eventId] = {eventType = eventType,
            checkAt = Server().unpausedRuntime + 1}
    end
end

function ChronicleSectorObserver.observePlayerEntry(playerIndex, x, y)
    if not onServer() then return nil, "server_only" end
    local sector = Sector()
    local sectorX, sectorY = sector:getCoordinates()
    if sectorX ~= x or sectorY ~= y then return nil, "coordinate_mismatch" end
    if observeLegacy(x, y) then return nil, "legacy_evidence" end

    local event, eventError = invokeCoordinator("getEventForSector", x, y)
    if not event then return nil, eventError end
    if event.state ~= "prepared" and event.state ~= "retryable" then
        return nil, event.state
    end
    local claimant = "chronicles:" .. event.eventId
    local claim, claimError = Territory.ClaimMaterialization("chronicles_event",
        x, y, claimant, 60)
    if not claim then return nil, claimError end
    local materialization = event.materialization or {}
    materialization.operationId = claim.id
    materialization.attempts = claim.attempts
    local transitioned, transitionError = invokeCoordinator("requestEventTransition",
        "sector_observer", event.eventId, event.revision, "materializing",
        {materialization = materialization})
    if not transitioned then
        Territory.RetryMaterialization("chronicles_event", x, y, claimant,
            transitionError or "coordinator_transition_failed", 60)
        return nil, transitionError
    end
    sector:addScriptOnce(MATERIALIZER, event.eventId, event.eventType,
        event.seed, claimant, transitioned.revision)
    if not sector:hasScript(MATERIALIZER) then
        Territory.RetryMaterialization("chronicles_event", x, y, claimant,
            "materializer_attachment_failed", 60)
        invokeCoordinator("requestEventTransition", "sector_observer", event.eventId,
            transitioned.revision, "retryable", {lastError = "materializer_attachment_failed"})
        return nil, "materializer_attachment_failed"
    end
    return transitioned, nil
end

return ChronicleSectorObserver
