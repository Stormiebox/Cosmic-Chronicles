local NewsSchema = include("cosmicvaultnews_schema")

local ChronicleState = {}

ChronicleState.KEYS = {
    state = "cc_state_v2",
    events = "cc_events_v2",
    receipts = "cc_receipts_v1",
    repairs = "cc_repair_audit_v1",
    player = "cc_player_v2",
    interaction = "cc_interaction_v1",
}

ChronicleState.LIMITS = {
    events = 256,
    receipts = 1024,
    repairScans = 128,
    repairHistory = 512,
    readArticleIds = 256,
    followedThreads = 64,
    leads = 64,
    recentDialogueIds = 20,
    vanillaEvidenceBaseline = 64,
}

ChronicleState.EVENT_TRANSITIONS = {
    pending = {prepared = true, expired = true, abandoned = true, repair_required = true},
    prepared = {materializing = true, retryable = true, abandoned = true, repair_required = true},
    materializing = {active = true, retryable = true, failed_permanent = true, repair_required = true},
    retryable = {prepared = true, materializing = true, failed_permanent = true,
        expired = true, abandoned = true, repair_required = true},
    active = {resolving = true, expired = true, abandoned = true, repair_required = true},
    resolving = {succeeded = true, failed_permanent = true, repair_required = true},
    repair_required = {pending = true, prepared = true, retryable = true, active = true,
        resolving = true, succeeded = true, abandoned = true, failed_permanent = true},
    succeeded = {}, expired = {}, abandoned = {}, failed_permanent = {},
}

ChronicleState.RECEIPT_TRANSITIONS = {
    prepared = {succeeded = true, failed_permanent = true, repair_required = true,
        abandoned = true},
    repair_required = {prepared = true, succeeded = true, failed_permanent = true,
        abandoned = true},
    succeeded = {}, failed_permanent = {}, abandoned = {},
}

ChronicleState.INTERACTION_TRANSITIONS = {
    available = {debit_prepared = true, reward_prepared = true, abandoned = true,
        repair_required = true},
    debit_prepared = {reward_prepared = true, resolving = true, repair_required = true},
    reward_prepared = {resolving = true, repair_required = true},
    resolving = {succeeded = true, failed_permanent = true, repair_required = true},
    repair_required = {available = true, debit_prepared = true, reward_prepared = true,
        resolving = true, succeeded = true, abandoned = true, failed_permanent = true},
    succeeded = {}, failed_permanent = {}, abandoned = {},
}

local function finiteInteger(value)
    return type(value) == "number" and value == value and value ~= math.huge
        and value ~= -math.huge and value % 1 == 0
end

function ChronicleState.DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    if getmetatable(value) ~= nil then return nil, "non_serializable" end
    seen = seen or {}
    if seen[value] then return nil, "non_serializable" end
    seen[value] = true
    local result = {}
    for key, item in pairs(value) do
        local keyCopy, keyError = ChronicleState.DeepCopy(key, seen)
        if keyError then return nil, keyError end
        local itemCopy, itemError = ChronicleState.DeepCopy(item, seen)
        if itemError then return nil, itemError end
        result[keyCopy] = itemCopy
    end
    seen[value] = nil
    return result, nil
end

function ChronicleState.CoordinateKey(x, y)
    if not finiteInteger(x) or not finiteInteger(y) then return nil, "invalid_coordinate" end
    return tostring(x) .. ":" .. tostring(y), nil
end

function ChronicleState.ParseCoordinate(value)
    if type(value) ~= "string" then return nil, nil, "invalid_coordinate" end
    local x, y = string.match(value, "^%s*(-?%d+)%s*[:_,x]%s*(-?%d+)%s*$")
    x, y = tonumber(x), tonumber(y)
    if not finiteInteger(x) or not finiteInteger(y) then return nil, nil, "invalid_coordinate" end
    return x, y, nil
end

local function stablePart(value)
    local hash, hashError = NewsSchema.StableHash(tostring(value))
    if not hash then return nil, hashError end
    return hash, nil
end

function ChronicleState.MakeEventId(eventType, x, y, discriminator)
    if type(eventType) ~= "string" or eventType == "" then return nil, "invalid_arguments" end
    local key, coordinateError = ChronicleState.CoordinateKey(x, y)
    if not key then return nil, coordinateError end
    local hash, hashError = stablePart(table.concat({eventType, key,
        tostring(discriminator or "default")}, "|"))
    if not hash then return nil, hashError end
    local slug = string.lower(string.gsub(eventType, "[^%w_.-]", "-"))
    return "cc:" .. slug .. ":" .. tostring(x) .. ":" .. tostring(y) .. ":" .. hash, nil
end

function ChronicleState.NewsRuleReceiptId(articleId, articleRevision, ruleId)
    if type(articleId) ~= "string" or not finiteInteger(articleRevision)
            or type(ruleId) ~= "string" then return nil, "invalid_arguments" end
    local hash, hashError = stablePart(articleId .. "|" .. articleRevision .. "|" .. ruleId)
    if not hash then return nil, hashError end
    return "news:" .. hash .. ":rule:" .. string.lower(string.gsub(ruleId, "[^%w_.-]", "-")), nil
end

function ChronicleState.PlayerMilestoneReceiptId(playerIndex, milestone)
    if not finiteInteger(playerIndex) or type(milestone) ~= "string" then
        return nil, "invalid_arguments"
    end
    return "player:" .. playerIndex .. ":vanilla:"
        .. string.lower(string.gsub(milestone, "[^%w_.-]", "-")) .. ":bonus", nil
end

function ChronicleState.PlayerEventReceiptId(playerIndex, eventId)
    if not finiteInteger(playerIndex) or type(eventId) ~= "string" then
        return nil, "invalid_arguments"
    end
    local hash, hashError = stablePart(eventId)
    if not hash then return nil, hashError end
    return "player:" .. playerIndex .. ":event:" .. hash .. ":reward", nil
end

function ChronicleState.EntityInteractionReceiptId(entityId, interactionType, discriminator)
    if type(entityId) ~= "string" or type(interactionType) ~= "string" then
        return nil, "invalid_arguments"
    end
    local hash, hashError = stablePart(entityId)
    if not hash then return nil, hashError end
    local result = "entity:" .. hash .. ":interaction:"
        .. string.lower(string.gsub(interactionType, "[^%w_.-]", "-"))
    if discriminator ~= nil then
        local discriminatorHash, discriminatorError = stablePart(discriminator)
        if not discriminatorHash then return nil, discriminatorError end
        result = result .. ":operation:" .. discriminatorHash
    end
    return result, nil
end

function ChronicleState.NewState(currentTime)
    return {
        schemaVersion = 2,
        revision = 0,
        migration = {state = "pending", version = 0, sources = {}, lastError = nil},
        sourceCursors = {newsRevision = 0, latestSequence = 0},
        ruleCooldowns = {},
        scheduler = {nextReconcileAt = currentTime or 0, nextAmbientAt = currentTime or 0},
        externalEvents = {},
        health = {newsManager = "unknown", dialogueManager = "unknown", queue = "unknown",
            lastSuccessfulReconcileAt = nil, reconciliationFailures = 0},
        repairRequired = nil,
        lastError = nil,
    }
end

function ChronicleState.NewEvents()
    return {schemaVersion = 2, revision = 0, events = {}, tombstones = {},
        migration = {state = "pending", version = 0}, lastError = nil, repairRequired = nil}
end

function ChronicleState.NewReceipts()
    return {schemaVersion = 1, revision = 0, receipts = {}, lastError = nil,
        repairRequired = nil}
end

function ChronicleState.NewRepairAudit()
    return {schemaVersion = 1, revision = 0, nextRepairId = 1, scans = {}, history = {},
        lastError = nil, repairRequired = nil}
end

function ChronicleState.NewPlayer(currentTime)
    return {
        schemaVersion = 2,
        revision = 0,
        news = {readThroughSequence = 0, readArticleIds = {}, followedThreads = {},
            lastFeedRevision = 0, notifications = {breakingChat = true,
                nearbyHazards = true, regularChat = false}},
        leads = {},
        recentDialogueIds = {},
        vanillaEvidenceBaseline = {},
        milestones = {},
        migration = {state = "pending", provenance = {}, lastError = nil,
            createdAt = currentTime or 0},
        repairRequired = nil,
        lastError = nil,
    }
end

function ChronicleState.NewEvent(options, currentTime)
    if type(options) ~= "table" or type(options.eventId) ~= "string"
            or type(options.eventType) ~= "string"
            or not finiteInteger(options.x) or not finiteInteger(options.y) then
        return nil, "invalid_arguments"
    end
    local trigger, triggerError = ChronicleState.DeepCopy(options.trigger or {})
    if not trigger then return nil, triggerError end
    local createdAt = currentTime or 0
    return {
        schemaVersion = 2,
        revision = 0,
        eventId = options.eventId,
        eventType = options.eventType,
        x = options.x,
        y = options.y,
        state = options.state or "pending",
        trigger = trigger,
        seed = options.seed or 0,
        createdAt = createdAt,
        updatedAt = createdAt,
        expiresAt = options.expiresAt,
        materialization = {queueKind = "chronicles_event", operationId = nil,
            attempts = 0, entityIds = {}, verifiedAt = nil},
        participants = {},
        outcome = nil,
        lastError = nil,
        repairRequired = nil,
    }, nil
end

function ChronicleState.NewReceipt(options, currentTime)
    if type(options) ~= "table" or type(options.receiptId) ~= "string"
            or type(options.operationKind) ~= "string" then return nil, "invalid_arguments" end
    local recipient, recipientError = ChronicleState.DeepCopy(options.recipient or {})
    if not recipient then return nil, recipientError end
    local sourceEvidence, evidenceError = ChronicleState.DeepCopy(options.sourceEvidence or {})
    if not sourceEvidence then return nil, evidenceError end
    local preparedAt = currentTime or 0
    return {
        schemaVersion = 1,
        revision = 0,
        receiptId = options.receiptId,
        operationKind = options.operationKind,
        state = "prepared",
        preparedAt = preparedAt,
        completedAt = nil,
        recipient = recipient,
        sourceEvidence = sourceEvidence,
        resultEvidence = nil,
        lastError = nil,
        repairRequired = nil,
    }, nil
end

function ChronicleState.NewInteraction(options, currentTime)
    if type(options) ~= "table" or type(options.eventId) ~= "string"
            or type(options.interactionType) ~= "string" then return nil, "invalid_arguments" end
    return {
        schemaVersion = 1,
        revision = 0,
        eventId = options.eventId,
        interactionType = options.interactionType,
        state = "available",
        claimantPlayerIndex = nil,
        ownerFactionIndex = options.ownerFactionIndex,
        operationId = nil,
        costSnapshot = nil,
        rewardSnapshot = nil,
        preparedAt = nil,
        completedAt = nil,
        receiptId = nil,
        lastError = nil,
        repairRequired = nil,
        createdAt = currentTime or 0,
        cycle = options.cycle or 1,
        completedPlayers = {},
    }, nil
end

function ChronicleState.RevisionMatches(record, expectedRevision)
    return type(record) == "table" and finiteInteger(expectedRevision)
        and record.revision == expectedRevision
end

function ChronicleState.Transition(record, nextState, transitions, fields, currentTime)
    if type(record) ~= "table" or type(record.state) ~= "string"
            or type(nextState) ~= "string" or type(transitions) ~= "table" then
        return nil, "invalid_arguments"
    end
    if record.state == nextState then return ChronicleState.DeepCopy(record) end
    if not transitions[record.state] or not transitions[record.state][nextState] then
        return nil, "invalid_transition"
    end
    local working, copyError = ChronicleState.DeepCopy(record)
    if not working then return nil, copyError end
    working.state = nextState
    for key, value in pairs(fields or {}) do
        local copied, fieldError = ChronicleState.DeepCopy(value)
        if fieldError then return nil, fieldError end
        working[key] = copied
    end
    working.revision = (working.revision or 0) + 1
    working.updatedAt = currentTime or working.updatedAt
    return working, nil
end

function ChronicleState.Count(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

return ChronicleState
