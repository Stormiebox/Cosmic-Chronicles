local Data = include("cosmicvaultdata")
local ChronicleState = include("cc_state")

local ChronicleInteractionController = {}
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local function copy(value)
    return ChronicleState.DeepCopy(value)
end

function ChronicleInteractionController.Now()
    return Server().unpausedRuntime
end

function ChronicleInteractionController.InvokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

function ChronicleInteractionController.Store(entity, current, record)
    record.revision = (current and current.revision or -1) + 1
    local stored, storeError = Data.SetRecord(entity, ChronicleState.KEYS.interaction, record)
    if not stored then return nil, storeError end
    return record, nil
end

function ChronicleInteractionController.Load(entity, options)
    local record, loadError = Data.GetRecord(entity, ChronicleState.KEYS.interaction, 1)
    if record then
        if record.state == "debit_prepared" or record.state == "reward_prepared"
                or record.state == "resolving" then
            local current = copy(record)
            record.state = "repair_required"
            record.lastError = "interrupted_interaction"
            record.repairRequired = "A charge or reward side effect cannot be proven."
            return ChronicleInteractionController.Store(entity, current, record)
        end
        return record, nil
    end
    if loadError ~= "missing" then return nil, loadError end
    local created, createError = ChronicleState.NewInteraction(options,
        ChronicleInteractionController.Now())
    if not created then return nil, createError end
    return ChronicleInteractionController.Store(entity, {revision = -1}, created)
end

function ChronicleInteractionController.Transition(entity, current, nextState, fields)
    local transitioned, transitionError = ChronicleState.Transition(current, nextState,
        ChronicleState.INTERACTION_TRANSITIONS, fields or {},
        ChronicleInteractionController.Now())
    if not transitioned then return nil, transitionError end
    transitioned.revision = current.revision
    return ChronicleInteractionController.Store(entity, current, transitioned)
end

function ChronicleInteractionController.PrepareReceipt(owner, entity, interactionType,
        playerIndex, sourceEvidence, resultEvidence)
    return ChronicleInteractionController.InvokeCoordinator("prepareInteractionReceipt",
        owner, tostring(entity.id), interactionType, playerIndex, sourceEvidence, resultEvidence)
end

function ChronicleInteractionController.FinishReceipt(owner, playerIndex, receipt,
        nextState, resultEvidence, errorText)
    return ChronicleInteractionController.InvokeCoordinator("transitionInteractionReceipt",
        owner, playerIndex, receipt.receiptId, receipt.revision, nextState,
        resultEvidence, errorText)
end

function ChronicleInteractionController.ResolveEvent(entity, summary, resultEvidence)
    local eventId = entity:getValue("cc_event_id")
    if type(eventId) ~= "string" then return nil, "missing_event_id" end
    local event, eventError = ChronicleInteractionController.InvokeCoordinator("getEvent", eventId)
    if not event then return nil, eventError end
    if event.state == "succeeded" then return event, nil end
    if event.state ~= "active" then return nil, "event_not_active" end
    local resolving, resolvingError = ChronicleInteractionController.InvokeCoordinator(
        "requestEventTransition", "event_resolver", eventId, event.revision, "resolving",
        {outcome = {kind = "interaction", entityId = tostring(entity.id), summary = summary}})
    if not resolving then return nil, resolvingError end
    return ChronicleInteractionController.InvokeCoordinator("requestEventTransition",
        "event_resolver", eventId, resolving.revision, "succeeded",
        {outcome = {kind = "interaction", entityId = tostring(entity.id),
            summary = summary, result = resultEvidence}})
end

function ChronicleInteractionController.RequireRepair(entity, current, owner, playerIndex,
        receipt, errorText)
    local repaired = ChronicleInteractionController.Transition(entity, current,
        "repair_required", {lastError = errorText,
            repairRequired = "Interaction side effects cannot be safely repeated."})
    if receipt then ChronicleInteractionController.FinishReceipt(owner, playerIndex,
        receipt, "repair_required", receipt.resultEvidence, errorText) end
    return repaired
end

return ChronicleInteractionController
