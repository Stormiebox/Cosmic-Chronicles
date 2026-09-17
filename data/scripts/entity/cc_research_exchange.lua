package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("faction")
include("relations")
include("stringutility")

local Data = include("cosmicvaultdata")
local ChronicleState = include("cc_state")

-- namespace ChronicleResearchExchange
ChronicleResearchExchange = {}
local self = ChronicleResearchExchange
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local OWNER = "data/scripts/entity/cc_research_exchange.lua"
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local REWARD_CREDITS = 1000000
local REWARD_REPUTATION = 1500

self.record = nil
self.blocked = nil

local function now()
    return Server().unpausedRuntime
end

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function store(record)
    record.revision = (self.record and self.record.revision or -1) + 1
    local stored, storeError = Data.SetRecord(Entity(), ChronicleState.KEYS.interaction, record)
    if not stored then return nil, storeError end
    self.record = record
    return record, nil
end

local function load()
    local record, loadError = Data.GetRecord(Entity(), ChronicleState.KEYS.interaction, 1)
    if record then
        self.record = record
        if record.state == "debit_prepared" or record.state == "reward_prepared"
                or record.state == "resolving" then
            record.state = "repair_required"
            record.lastError = "interrupted_exchange"
            record.repairRequired = "Fragment debit or reward delivery cannot be proven."
            store(record)
        end
        return true
    end
    if loadError ~= "missing" then self.blocked = loadError return nil, loadError end
    record = ChronicleState.NewInteraction({
        eventId = "research:" .. tostring(Entity().id),
        interactionType = "research_exchange",
        ownerFactionIndex = Entity().factionIndex,
    }, now())
    self.record = {revision = -1}
    return store(record)
end

local function transition(nextState, fields)
    local transitioned, transitionError = ChronicleState.Transition(self.record, nextState,
        ChronicleState.INTERACTION_TRANSITIONS, fields or {}, now())
    if not transitioned then return nil, transitionError end
    -- store() always recomputes .revision from self.record (the DB write's own revision
    -- counter), so ChronicleState.Transition's internal increment on `transitioned` is
    -- discarded here rather than assigned; no need to reset it back first.
    return store(transitioned)
end

local function resolvePlayer()
    local buyer, ship, targetPlayer = getInteractingFaction(callingPlayer)
    if not buyer or not ship or not targetPlayer then return nil, nil, nil, "invalid_interactor" end
    if ship:getNearestDistance(Entity()) > 1000 then return nil, nil, nil, "too_far" end
    return buyer, ship, targetPlayer, nil
end

function ChronicleResearchExchange.initialize()
    if onServer() then load() end
end

function ChronicleResearchExchange.interactionPossible(playerIndex, option)
    local targetPlayer = Player(playerIndex)
    if not targetPlayer or not targetPlayer.craft then return false end
    if targetPlayer.craft:getNearestDistance(Entity()) > 1000 then return false end
    if onServer() and (self.blocked or not self.record or self.record.state ~= "available") then
        return false
    end
    return true
end

function ChronicleResearchExchange.initUI()
    ScriptUI():registerInteraction("Turn in Encrypted Log Fragment"%_t, "onTurnInLogFragment")
end

function ChronicleResearchExchange.onTurnInLogFragment()
    local dialog = {
        text = "We can authenticate one encrypted log fragment and pay for its telemetry."%_t,
        answers = {
            {answer = "Exchange 1 fragment for 1,000,000 credits."%_t,
                onSelect = "onConfirmExchange"},
            {answer = "Not now."%_t},
        },
    }
    ScriptUI():showDialog(dialog)
end

function ChronicleResearchExchange.onConfirmExchange()
    invokeServerFunction("exchangeServer")
end

function ChronicleResearchExchange.exchangeServer()
    if not onServer() then return end
    local buyer, ship, targetPlayer, playerError = resolvePlayer()
    if not targetPlayer then return end
    if self.blocked or not self.record or self.record.state ~= "available" then return end
    local fragments = tonumber(targetPlayer:getValue("cc_log_fragments")) or 0
    if fragments < 1 then
        invokeClientFunction(targetPlayer, "showExchangeResult", false,
            "No encrypted log fragments are available.")
        return
    end

    local resultEvidence = {credits = REWARD_CREDITS, reputation = REWARD_REPUTATION,
        stationFactionIndex = Entity().factionIndex, factionIndex = buyer.index}
    local receipt, receiptError, created = invokeCoordinator("prepareInteractionReceipt",
        OWNER, tostring(Entity().id), "research_exchange", targetPlayer.index,
        {fragmentsBefore = fragments, entityId = tostring(Entity().id),
            receiptDiscriminator = "cycle:" .. tostring(self.record.cycle or 1)}, resultEvidence)
    if not receipt then return end
    if not created then
        if receipt.state == "prepared" then
            transition("repair_required", {receiptId = receipt.receiptId,
                lastError = "interrupted_exchange", repairRequired = "Receipt already prepared."})
            invokeCoordinator("transitionInteractionReceipt", OWNER, targetPlayer.index,
                receipt.receiptId, receipt.revision, "repair_required",
                receipt.resultEvidence, "interrupted_exchange")
        end
        return
    end

    local prepared, prepareError = transition("debit_prepared", {
        claimantPlayerIndex = targetPlayer.index,
        operationId = receipt.receiptId,
        receiptId = receipt.receiptId,
        costSnapshot = {fragments = 1, fragmentsBefore = fragments},
        rewardSnapshot = resultEvidence,
        preparedAt = now(),
    })
    if not prepared then
        invokeCoordinator("transitionInteractionReceipt", OWNER, targetPlayer.index,
            receipt.receiptId, receipt.revision, "repair_required", receipt.resultEvidence,
            prepareError or "local_prepare_failed")
        return
    end

    local debited = pcall(function()
        targetPlayer:setValue("cc_log_fragments", fragments - 1)
    end)
    if not debited then
        transition("repair_required", {lastError = "fragment_debit_failed",
            repairRequired = "Fragment debit failed."})
        invokeCoordinator("transitionInteractionReceipt", OWNER, targetPlayer.index,
            receipt.receiptId, receipt.revision, "repair_required", receipt.resultEvidence,
            "fragment_debit_failed")
        return
    end
    local rewardPrepared = transition("reward_prepared")
    if not rewardPrepared then return end

    local delivered = pcall(function()
        buyer:receive("Encrypted Log Fragment", REWARD_CREDITS)
        local stationFaction = Faction(Entity().factionIndex)
        if stationFaction then changeRelations(buyer, stationFaction,
            REWARD_REPUTATION, RelationChangeType.General) end
    end)
    if not delivered then
        transition("repair_required", {lastError = "reward_delivery_failed",
            repairRequired = "Fragment was debited but reward delivery failed."})
        invokeCoordinator("transitionInteractionReceipt", OWNER, targetPlayer.index,
            receipt.receiptId, receipt.revision, "repair_required", receipt.resultEvidence,
            "reward_delivery_failed")
        return
    end

    transition("resolving")
    local completed = invokeCoordinator("transitionInteractionReceipt", OWNER,
        targetPlayer.index, receipt.receiptId, receipt.revision, "succeeded",
        {credits = REWARD_CREDITS, reputation = REWARD_REPUTATION, deliveredAt = now()})
    if completed then
        local succeeded = transition("succeeded", {completedAt = now()})
        if succeeded then
            local nextRecord = ChronicleState.NewInteraction({
                eventId = "research:" .. tostring(Entity().id),
                interactionType = "research_exchange",
                ownerFactionIndex = Entity().factionIndex,
                cycle = (succeeded.cycle or 1) + 1,
            }, now())
            self.record = store(nextRecord) or succeeded
        end
        invokeClientFunction(targetPlayer, "showExchangeResult", true,
            "Exchange complete. One encrypted fragment was accepted.")
    else
        transition("repair_required", {lastError = "receipt_completion_failed",
            repairRequired = "Reward delivered; receipt completion is ambiguous."})
    end
end

function ChronicleResearchExchange.showExchangeResult(success, message)
    if not onClient() then return end
    ScriptUI():showDialog({text = tostring(message), answers = {{answer = "Understood."%_t}}})
end

callable(ChronicleResearchExchange, "exchangeServer")

return ChronicleResearchExchange
