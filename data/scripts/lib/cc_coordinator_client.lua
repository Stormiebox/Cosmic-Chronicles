-- Server-side bridge to the galaxy-owned Chronicle coordinator. Every Chronicle script talks
-- to the coordinator through Galaxy():invokeFunction, so the call and its result handling live
-- here once instead of in each caller.
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local unpackValues = table.unpack or unpack

local CoordinatorClient = {}

local function packValues(...)
    return {n = select("#", ...), ...}
end

-- invokeFunction returns (status, results...). A nonzero status means the coordinator is not
-- attached or the call failed; otherwise the coordinator's own results follow. The explicit
-- count keeps trailing nils, which the coordinator uses for its (value, nil) returns.
function CoordinatorClient.Invoke(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

return CoordinatorClient
