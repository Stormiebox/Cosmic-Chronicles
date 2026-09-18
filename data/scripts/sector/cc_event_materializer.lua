package.path = package.path .. ";data/scripts/lib/?.lua"

local Territory = include("cosmicvaultterritory")
local EventContract = include("cc_event_contract")

-- namespace ChronicleEventMaterializer
ChronicleEventMaterializer = {}
local self = ChronicleEventMaterializer
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local EVENT_SCRIPTS = {
    ancient_data_cache = "data/scripts/events/cc_ancientdatacache.lua",
    bounty_ambush = "data/scripts/events/cc_bounty_ambush.lua",
    graveyard = "data/scripts/events/cc_derelictgraveyard.lua",
    stranded_diplomat = "data/scripts/events/cc_diplomatescort.lua",
    ghost_ship = "data/scripts/events/cc_ghostship.lua",
    hidden_stash = "data/scripts/events/cc_hiddenstash.lua",
    refugee_convoy = "data/scripts/events/cc_refugeeconvoy.lua",
    rogue_ai_probe = "data/scripts/events/cc_rogueaiprobe.lua",
    cultural_monument = "data/scripts/events/cc_spawnmonument.lua",
    eclipse_lore_anomaly = "data/scripts/events/cc_ancientdatacache.lua",
}

self.eventId = nil
self.eventType = nil
self.seed = 0
self.claimant = nil
self.eventRevision = nil
self.elapsed = 0
self.spawnRequested = false

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function retry(errorText)
    local x, y = Sector():getCoordinates()
    Territory.RetryMaterialization("chronicles_event", x, y, self.claimant,
        errorText, math.min(300, 30 * math.max(1, self.elapsed)))
    invokeCoordinator("requestEventTransition", "event_materializer", self.eventId,
        self.eventRevision, "retryable", {lastError = errorText})
    terminate()
end

local function requireRepair(errorText, entityIds)
    local x, y = Sector():getCoordinates()
    Territory.RequireMaterializationRepair("chronicles_event", x, y, self.claimant,
        errorText)
    local current = invokeCoordinator("getEvent", self.eventId)
    local materialization = current and current.materialization or {
        queueKind = "chronicles_event", attempts = 0}
    materialization.entityIds = entityIds or materialization.entityIds or {}
    invokeCoordinator("requestEventTransition", "event_materializer", self.eventId,
        self.eventRevision, "repair_required", {lastError = errorText,
            repairRequired = "Materialization may have produced partial side effects.",
            materialization = materialization})
    terminate()
end

function ChronicleEventMaterializer.initialize(eventId, eventType, seed, claimant, eventRevision)
    if not onServer() then return end
    self.eventId = eventId
    self.eventType = eventType
    self.seed = seed or 0
    self.claimant = claimant
    self.eventRevision = eventRevision
    if type(eventId) ~= "string" or type(eventType) ~= "string"
            or type(claimant) ~= "string" or type(eventRevision) ~= "number" then
        terminate()
    end
end

function ChronicleEventMaterializer.getUpdateInterval()
    return 0.5
end

function ChronicleEventMaterializer.updateServer(timeStep)
    self.elapsed = self.elapsed + timeStep
    if not self.spawnRequested then
        local eventScript = EVENT_SCRIPTS[self.eventType]
        if not eventScript then retry("unsupported_event_type") return end
        self.spawnRequested = true
        -- eventType lets a shared event script (e.g. cc_ancientdatacache.lua, reused by
        -- both ancient_data_cache and eclipse_lore_anomaly) tell which narrative it's spawning.
        Sector():addScriptOnce(eventScript, self.eventId, self.seed, self.eventType)
        return
    end

    local entities = {Sector():getEntitiesByScriptValue("cc_event_id", self.eventId)}
    local contract = EventContract.Get(self.eventId)
    if contract and contract.status == "failed" then
        if #entities > 0 then requireRepair(contract.lastError or "partial_spawn", {})
        else retry(contract.lastError or "spawn_failed") end
        return
    end
    if contract and contract.status == "succeeded" then
        local entityIds = {}
        for _, entity in ipairs(entities) do
            if valid(entity) then entityIds[#entityIds + 1] = tostring(entity.id) end
        end
        if #entityIds ~= contract.expectedCount or contract.actualCount ~= contract.expectedCount then
            requireRepair("materialization_count_mismatch", entityIds)
            return
        end
        local materialization = {queueKind = "chronicles_event",
            operationId = "chronicles_event:" .. tostring(self.eventId),
            attempts = 1, entityIds = entityIds, verifiedAt = Server().unpausedRuntime}
        local active, activeError = invokeCoordinator("requestEventTransition",
            "event_materializer", self.eventId, self.eventRevision, "active",
            -- false, not nil: pairs()-based field copy in ChronicleState.Transition never
            -- sees a nil-valued key, so omitting these would leave a stale lastError/
            -- repairRequired from an earlier retry cycle on this now-healthy event.
            {materialization = materialization, lastError = false, repairRequired = false})
        if not active then retry(activeError or "active_transition_failed") return end
        local x, y = Sector():getCoordinates()
        local completed, completeError = Territory.CompleteMaterialization(
            "chronicles_event", x, y, self.claimant,
            {eventId = self.eventId, entityIds = entityIds, verified = true})
        if not completed then
            invokeCoordinator("requestEventTransition", "event_materializer", self.eventId,
                active.revision, "repair_required", {lastError = completeError,
                    repairRequired = "queue_completion_ambiguous"})
        end
        terminate()
        return
    end
    if self.elapsed >= 5 then
        if #entities > 0 or (contract and contract.status == "materializing") then
            local entityIds = {}
            for _, entity in ipairs(entities) do
                if valid(entity) then entityIds[#entityIds + 1] = tostring(entity.id) end
            end
            requireRepair("spawn_completion_ambiguous", entityIds)
        else
            retry("spawn_not_verified")
        end
    end
end

function ChronicleEventMaterializer.secure()
    return {eventId = self.eventId, eventType = self.eventType, seed = self.seed,
        claimant = self.claimant, eventRevision = self.eventRevision,
        elapsed = self.elapsed, spawnRequested = self.spawnRequested}
end

function ChronicleEventMaterializer.restore(data)
    if type(data) ~= "table" then return end
    self.eventId = data.eventId
    self.eventType = data.eventType
    self.seed = data.seed or 0
    self.claimant = data.claimant
    self.eventRevision = data.eventRevision
    self.elapsed = data.elapsed or 0
    self.spawnRequested = data.spawnRequested == true
end

return ChronicleEventMaterializer
