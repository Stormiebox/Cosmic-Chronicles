package.path = package.path .. ";data/scripts/lib/?.lua"

-- namespace ChronicleProbeTracker
ChronicleProbeTracker = {}
local self = ChronicleProbeTracker
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
self.eventId = nil
self.timeout = 180
self.elapsed = 0
self.escaping = false

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function resolve(nextState, summary)
    local event = invokeCoordinator("getEvent", self.eventId)
    if not event or event.state ~= "active" then return nil end
    local outcome = {kind = nextState, entityId = tostring(Entity().id), summary = summary}
    if nextState == "expired" or nextState == "abandoned" then
        return invokeCoordinator("requestEventTransition", "event_resolver", self.eventId,
            event.revision, nextState, {outcome = outcome})
    end
    local resolving = invokeCoordinator("requestEventTransition", "event_resolver",
        self.eventId, event.revision, "resolving",
        {outcome = outcome})
    if not resolving then return nil end
    return invokeCoordinator("requestEventTransition", "event_resolver", self.eventId,
        resolving.revision, nextState,
        {outcome = outcome})
end

function ChronicleProbeTracker.initialize(eventId, timeout)
    if not onServer() then return end
    self.eventId = eventId
    self.timeout = tonumber(timeout) or 180
    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function ChronicleProbeTracker.getUpdateInterval() return 1 end

function ChronicleProbeTracker.updateServer(timeStep)
    if self.escaping then return end
    self.elapsed = self.elapsed + timeStep
    if self.elapsed < self.timeout then return end
    self.escaping = true
    resolve("expired", "The rogue probe completed its scan and escaped the sector.")
    Sector():deleteEntityJumped(Entity())
end

function ChronicleProbeTracker.onDestroyed(entityId)
    if self.escaping or tostring(entityId) ~= tostring(Entity().id) then return end
    resolve("succeeded", "The rogue probe was destroyed before it could escape.")
end

function ChronicleProbeTracker.secure()
    return {eventId = self.eventId, timeout = self.timeout, elapsed = self.elapsed,
        escaping = self.escaping}
end

function ChronicleProbeTracker.restore(data)
    if type(data) ~= "table" then return end
    self.eventId = data.eventId
    self.timeout = data.timeout or 180
    self.elapsed = data.elapsed or 0
    self.escaping = data.escaping == true
end

return ChronicleProbeTracker
