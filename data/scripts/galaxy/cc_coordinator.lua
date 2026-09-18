package.path = package.path .. ";data/scripts/lib/?.lua"

local Data = include("cosmicvaultdata")
local News = include("cosmicvaultnews")
local Dialogue = include("cosmicvaultdialogue")
local Territory = include("cosmicvaultterritory")
local ChronicleState = include("cc_state")
local ChronicleRules = include("cc_narrative_rules")
local DialogueCatalog = include("cc_dialogue_catalog")
local ChronicleNews = include("cc_news")
local ChronicleGoods = include("cc_goods")

-- namespace ChronicleCoordinator
ChronicleCoordinator = {}
local self = ChronicleCoordinator

local LEGACY_NEWS_GENERATOR = "data/scripts/server/cc_newsgenerator.lua"
local LEGACY_STOCK_MARKET = "data/scripts/server/background/cc_stockmarket.lua"
local RECONCILE_INTERVAL = 10
local RECONCILE_ARTICLES_PER_TICK = 8
local MAX_QUERY_PAGES = 11
local MAX_AUDIENCE_SCANS = 16
local TERMINAL_EVENTS = {succeeded = true, expired = true, abandoned = true,
    failed_permanent = true}
local INTERACTION_OWNERS = {
    ["data/scripts/entity/cc_research_exchange.lua"] = true,
    ["data/scripts/entity/cc_blackbox.lua"] = true,
    ["data/scripts/entity/cc_refugeedialogue.lua"] = true,
    ["data/scripts/entity/cc_diplomat.lua"] = true,
    ["data/scripts/entity/cc_ghostship.lua"] = true,
    ["data/scripts/entity/cc_factionmonument.lua"] = true,
}

local RECORDS = {
    state = {key = ChronicleState.KEYS.state, version = 2,
        constructor = ChronicleState.NewState},
    events = {key = ChronicleState.KEYS.events, version = 2,
        constructor = ChronicleState.NewEvents},
    receipts = {key = ChronicleState.KEYS.receipts, version = 1,
        constructor = ChronicleState.NewReceipts},
    repairs = {key = ChronicleState.KEYS.repairs, version = 1,
        constructor = ChronicleState.NewRepairAudit},
}

self.records = {}
self.blocked = {}
self.pendingArticleIds = {}
self.reconcileQueue = nil
self.reconcileTarget = nil
self.registrationDue = true
self.migrationDue = true

local function now()
    local server = Server()
    return server and server.unpausedRuntime or 0
end

local function count(values)
    return ChronicleState.Count(values)
end

local function copy(value)
    local result = ChronicleState.DeepCopy(value)
    return result
end

local function validRootRecord(record, version)
    return type(record) == "table" and record.schemaVersion == version
        and type(record.revision) == "number" and record.revision >= 0
        and record.revision % 1 == 0
end

local function loadRecord(name)
    local definition = RECORDS[name]
    local record, loadError = Data.GetRecord(Server(), definition.key, definition.version)
    if record and validRootRecord(record, definition.version) then
        self.records[name] = record
        return true
    end
    if loadError == "missing" then
        record = definition.constructor(now())
        local stored, storeError = Data.SetRecord(Server(), definition.key, record)
        if not stored then
            self.blocked[name] = storeError
            return nil, storeError
        end
        self.records[name] = record
        return true
    end
    self.blocked[name] = loadError or "corrupt"
    return nil, self.blocked[name]
end

local function commit(name, mutator)
    if self.blocked[name] then return nil, self.blocked[name] end
    local current = self.records[name]
    if not current then return nil, "record_unavailable" end
    local working, copyError = ChronicleState.DeepCopy(current)
    if not working then return nil, copyError end
    local changed, mutationError = mutator(working)
    if mutationError then return nil, mutationError end
    if changed == false then return copy(current), nil, false end
    working.revision = (current.revision or 0) + 1
    local stored, storeError = Data.SetRecord(Server(), RECORDS[name].key, working)
    if not stored then return nil, storeError end
    self.records[name] = working
    return copy(working), nil, true
end

local function setHealth(newsHealth, dialogueHealth, lastError)
    if not self.records.state then return end
    commit("state", function(record)
        local changed = false
        if newsHealth and record.health.newsManager ~= newsHealth then
            record.health.newsManager = newsHealth
            changed = true
        end
        if dialogueHealth and record.health.dialogueManager ~= dialogueHealth then
            record.health.dialogueManager = dialogueHealth
            changed = true
        end
        if lastError ~= nil and record.lastError ~= lastError then
            record.lastError = lastError
            changed = true
        end
        return changed
    end)
end

local function registerVaultContracts()
    -- Populates Catalog.entries on first call, at genuine runtime (this function only ever
    -- runs from initialize()/updateServer(), both post-onServer()). Guarded, so the repeated
    -- calls from updateServer()'s registrationDue retry are harmless no-ops.
    DialogueCatalog.ensurePopulated()
    local _, newsError = News.RegisterPublisher(DialogueCatalog.publisher)
    local dialoguePublisher, dialoguePublisherError = Dialogue.RegisterPublisher(
        DialogueCatalog.publisher)
    local catalogResult, catalogError = Dialogue.RegisterEntries(
        DialogueCatalog.publisher.publisherId, DialogueCatalog.entries)

    local newsHealth = newsError and "unavailable" or "healthy"
    local dialogueHealth = (dialoguePublisher and catalogResult
        and catalogResult.registered == #DialogueCatalog.entries) and "healthy" or "unavailable"
    local errorText = newsError or dialoguePublisherError or catalogError
    setHealth(newsHealth, dialogueHealth, errorText)
    self.registrationDue = errorText ~= nil
    return errorText == nil, errorText
end

local function appendBounded(array, value, limit)
    array[#array + 1] = value
    while #array > limit do table.remove(array, 1) end
end

local function addMigrationFinding(kind, itemId, evidence, actions)
    if not self.records.repairs then return end
    commit("repairs", function(record)
        local repairId = "chronicles:migration:" .. tostring(record.nextRepairId)
        record.nextRepairId = record.nextRepairId + 1
        record.scans[repairId] = {
            schemaVersion = 1,
            repairId = repairId,
            scope = "migration",
            state = "open",
            createdAt = now(),
            findings = {{kind = kind, itemId = itemId, evidence = tostring(evidence),
                permittedActions = actions or {"retry", "abandon"}}},
            observedRevisions = {events = self.records.events and self.records.events.revision or -1,
                receipts = self.records.receipts and self.records.receipts.revision or -1},
        }
        return true
    end)
end

local function findCoordinateEvent(x, y, exceptId)
    for eventId, event in pairs(self.records.events and self.records.events.events or {}) do
        if eventId ~= exceptId and event.x == x and event.y == y
                and not TERMINAL_EVENTS[event.state] then return event end
    end
end

local function createEvent(options)
    local existing = self.records.events.events[options.eventId]
    if existing then return copy(existing), nil, false end
    local event, eventError = ChronicleState.NewEvent(options, now())
    if not event then return nil, eventError end
    local saved, saveError = commit("events", function(record)
        if record.events[options.eventId] then return false end
        if count(record.events) >= ChronicleState.LIMITS.events then
            return nil, "event_limit_reached"
        end
        record.events[options.eventId] = event
        return true
    end)
    if not saved then return nil, saveError end
    return copy(self.records.events.events[options.eventId]), nil, true
end

local function mutateEvent(eventId, mutator)
    local result, mutationError
    local saved, saveError = commit("events", function(record)
        local event = record.events[eventId]
        if not event then return nil, "not_found" end
        result, mutationError = mutator(event)
        if mutationError then return nil, mutationError end
        if result == false then return false end
        event.revision = (event.revision or 0) + 1
        event.updatedAt = now()
        return true
    end)
    if not saved then return nil, saveError end
    return copy(self.records.events.events[eventId]), nil
end

local function queueEvent(event)
    local queued, queueError = Territory.QueueMaterialization("chronicles_event",
        event.x, event.y, {
            schemaVersion = 1,
            eventId = event.eventId,
            eventType = event.eventType,
            seed = event.seed,
            expiresAt = event.expiresAt,
        })
    if not queued then
        mutateEvent(event.eventId, function(current)
            current.state = "repair_required"
            current.lastError = queueError
            current.repairRequired = queueError
            return true
        end)
        addMigrationFinding("materialization_queue", event.eventId, queueError,
            {"retry", "abandon"})
        return nil, queueError
    end
    if event.state == "pending" then
        return mutateEvent(event.eventId, function(current)
            current.state = "prepared"
            current.materialization.operationId = queued.id
            current.materialization.queueKind = "chronicles_event"
            return true
        end)
    end
    return event, nil
end

local function parseLegacyList(value)
    local coordinates = {}
    local invalid = {}
    if value == nil or value == "" then return coordinates, invalid end
    if type(value) ~= "string" then return coordinates, {tostring(value)} end
    for token in string.gmatch(value .. ";", "(.-);") do
        local trimmed = token:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            local x, y, parseError = ChronicleState.ParseCoordinate(trimmed)
            if parseError then invalid[#invalid + 1] = trimmed
            else coordinates[#coordinates + 1] = {x = x, y = y, token = trimmed} end
        end
    end
    return coordinates, invalid
end

local function migrateLegacyCoordinates(key, eventType)
    local coordinates, invalid = parseLegacyList(Server():getValue(key))
    local migrated = 0
    local conflicts = 0
    for _, coordinate in ipairs(coordinates) do
        local eventId = ChronicleState.MakeEventId(eventType, coordinate.x, coordinate.y,
            "legacy:" .. key)
        local conflict = findCoordinateEvent(coordinate.x, coordinate.y, eventId)
        local event, eventError = createEvent({
            eventId = eventId,
            eventType = eventType,
            x = coordinate.x,
            y = coordinate.y,
            state = conflict and "repair_required" or "pending",
            trigger = {kind = "legacy_delimiter", key = key, token = coordinate.token},
            seed = tonumber(string.sub(eventId, -8), 16) or 0,
        })
        if event and not conflict then
            local _, queueError = queueEvent(event)
            if not queueError then migrated = migrated + 1 end
        elseif conflict then
            conflicts = conflicts + 1
            mutateEvent(eventId, function(current)
                current.lastError = "coordinate_conflict"
                current.repairRequired = "Existing event " .. tostring(conflict.eventId)
                    .. " already owns this coordinate."
                return true
            end)
            addMigrationFinding("coordinate_conflict", eventId,
                "conflicts with " .. tostring(conflict.eventId), {"retry", "abandon"})
        elseif eventError then
            addMigrationFinding("legacy_event", key, eventError, {"retry", "abandon"})
        end
    end
    for _, token in ipairs(invalid) do
        addMigrationFinding("invalid_legacy_coordinate", key, token, {"abandon"})
    end
    return migrated, #invalid, conflicts
end

local function importLegacyGeneratorState()
    local galaxy = Galaxy()
    local provenance = {state = "not_attached", reportedBosses = {}, knownActiveFactions = {}}
    if galaxy:hasScript(LEGACY_NEWS_GENERATOR) then
        local status, legacyState = galaxy:invokeFunction(LEGACY_NEWS_GENERATOR,
            "exportLegacyState")
        if status == 0 and type(legacyState) == "table" then
            provenance = copy(legacyState)
            provenance.state = "imported"
            galaxy:removeScript(LEGACY_NEWS_GENERATOR)
        else
            provenance.state = "repair_required"
            provenance.lastError = "legacy_export_failed:" .. tostring(status)
            addMigrationFinding("legacy_news_generator", LEGACY_NEWS_GENERATOR,
                provenance.lastError, {"retry", "abandon"})
        end
    end
    if galaxy:hasScript(LEGACY_STOCK_MARKET) then galaxy:removeScript(LEGACY_STOCK_MARKET) end
    return provenance
end

local function performMigration()
    local state = self.records.state
    if not state or state.migration.state == "complete"
            or state.migration.state == "repair_required" then
        self.migrationDue = false
        return true
    end
    if not self.records.events or not self.records.repairs then return nil, "record_unavailable" end

    commit("state", function(record)
        record.migration.state = "scanning"
        return true
    end)
    local bountyCount, bountyInvalid, bountyConflicts = migrateLegacyCoordinates(
        "cc_active_bounties", "bounty_ambush")
    local stashCount, stashInvalid, stashConflicts = migrateLegacyCoordinates(
        "cc_hidden_stashes", "hidden_stash")
    local generator = importLegacyGeneratorState()
    local hasRepair = bountyInvalid > 0 or stashInvalid > 0
        or bountyConflicts > 0 or stashConflicts > 0
        or generator.state == "repair_required"

    commit("state", function(record)
        record.migration.state = hasRepair and "repair_required" or "complete"
        record.migration.version = 2
        record.migration.sources = {
            newsV1 = {state = "owned_by_vault_news_v2", originalPreserved = true},
            activeBounties = {state = "imported", count = bountyCount,
                invalid = bountyInvalid, conflicts = bountyConflicts,
                originalPreserved = true},
            hiddenStashes = {state = "imported", count = stashCount,
                invalid = stashInvalid, conflicts = stashConflicts,
                originalPreserved = true},
            newsGenerator = generator,
        }
        record.migration.lastError = hasRepair and "migration_findings_require_review" or nil
        record.repairRequired = hasRepair and "migration_findings_require_review" or nil
        return true
    end)
    self.migrationDue = false
    return not hasRepair, hasRepair and "repair_required" or nil
end

local function getArticleForAnyAudience(articleId)
    local article, articleError = News.GetArticle(articleId)
    if article or articleError ~= "not_found" then return article, articleError end
    local players = {Server():getOnlinePlayers()}
    for index = 1, math.min(#players, MAX_AUDIENCE_SCANS) do
        local player = players[index]
        if player then
            article, articleError = News.GetArticle(articleId,
                {audiencePlayerIndex = player.index})
            if article then return article, nil end
        end
    end
    return nil, articleError
end

local function queryAudience(playerIndex)
    local articles = {}
    local beforeSequence
    local feedRevision, latestSequence
    for _ = 1, MAX_QUERY_PAGES do
        local page, queryError = News.Query({
            pageSize = 50,
            beforeSequence = beforeSequence,
            includeArchive = true,
            audiencePlayerIndex = playerIndex,
        })
        if not page then return nil, queryError end
        feedRevision = page.feedRevision
        latestSequence = page.latestSequence
        for _, article in ipairs(page.items or {}) do articles[article.articleId] = article end
        if not page.hasMore or not page.nextCursor then break end
        beforeSequence = page.nextCursor
    end
    return articles, nil, feedRevision, latestSequence
end

local function buildReconcileQueue()
    local combined = {}
    local globalArticles, globalError, feedRevision, latestSequence = queryAudience(nil)
    if not globalArticles then return nil, globalError end
    for articleId, article in pairs(globalArticles) do combined[articleId] = article end

    local players = {Server():getOnlinePlayers()}
    for index = 1, math.min(#players, MAX_AUDIENCE_SCANS) do
        local player = players[index]
        if player then
            local visible = queryAudience(player.index)
            for articleId, article in pairs(visible or {}) do combined[articleId] = article end
        end
    end
    for articleId in pairs(self.pendingArticleIds) do
        local article = getArticleForAnyAudience(articleId)
        if article then combined[articleId] = article end
    end
    self.pendingArticleIds = {}

    local queue = {}
    for _, article in pairs(combined) do queue[#queue + 1] = article end
    table.sort(queue, function(left, right)
        if left.sequence == right.sequence then return left.articleId < right.articleId end
        return left.sequence < right.sequence
    end)
    self.reconcileQueue = queue
    self.reconcileTarget = {feedRevision = feedRevision or 0,
        latestSequence = latestSequence or 0}
    return true
end

local function prepareRuleReceipt(article, rule, selection)
    local receiptId, idError = ChronicleState.NewsRuleReceiptId(
        article.articleId, article.revision, rule.ruleId)
    if not receiptId then return nil, idError end
    local existing = self.records.receipts.receipts[receiptId]
    if existing then return copy(existing), nil, false end
    local receipt = ChronicleState.NewReceipt({
        receiptId = receiptId,
        operationKind = "narrative_rule",
        sourceEvidence = {articleId = article.articleId, articleRevision = article.revision,
            ruleId = rule.ruleId, sourceSequence = article.sequence},
        recipient = {kind = "galaxy"},
    }, now())
    receipt.resultEvidence = selection
    local saved, saveError = commit("receipts", function(record)
        if record.receipts[receiptId] then return false end
        if count(record.receipts) >= ChronicleState.LIMITS.receipts then
            return nil, "receipt_limit_reached"
        end
        record.receipts[receiptId] = receipt
        return true
    end)
    if not saved then return nil, saveError end
    return copy(self.records.receipts.receipts[receiptId]), nil, true
end

local function finishReceipt(receiptId, state, result, errorText)
    return commit("receipts", function(record)
        local receipt = record.receipts[receiptId]
        if not receipt then return nil, "not_found" end
        if receipt.state == state then return false end
        local transitioned, transitionError = ChronicleState.Transition(receipt, state,
            ChronicleState.RECEIPT_TRANSITIONS, {
                completedAt = state == "succeeded" and now() or nil,
                resultEvidence = result or receipt.resultEvidence,
                lastError = errorText,
                repairRequired = state == "repair_required" and errorText or nil,
            }, now())
        if not transitioned then return nil, transitionError end
        record.receipts[receiptId] = transitioned
        return true
    end)
end

local function materializeRuleSelection(article, rule, receipt)
    local selection = receipt.resultEvidence or {}
    if not selection.selected then
        return finishReceipt(receipt.receiptId, "succeeded", selection)
    end
    local location = article.location
    local x, y = math.floor(location.x), math.floor(location.y)
    local eventId, eventIdError = ChronicleState.MakeEventId(
        selection.eventType, x, y, receipt.receiptId)
    if not eventId then return nil, eventIdError end
    selection.eventId = eventId

    local conflict = findCoordinateEvent(x, y, eventId)
    if conflict then
        local reason = "coordinate_owned_by:" .. tostring(conflict.eventId)
        finishReceipt(receipt.receiptId, "repair_required", selection, reason)
        addMigrationFinding("narrative_coordinate_conflict", receipt.receiptId, reason,
            {"retry", "abandon"})
        return nil, "coordinate_conflict"
    end

    local event, eventError = createEvent({
        eventId = eventId,
        eventType = selection.eventType,
        x = x,
        y = y,
        state = "pending",
        trigger = {kind = "news_rule", ruleId = rule.ruleId,
            articleId = article.articleId, sourceRevision = article.revision},
        seed = tonumber(string.sub(eventId, -8), 16) or 0,
        expiresAt = now() + selection.expirySeconds,
    })
    if not event then
        finishReceipt(receipt.receiptId, "repair_required", selection, eventError)
        return nil, eventError
    end
    local queued, queueError = queueEvent(event)
    if not queued then
        finishReceipt(receipt.receiptId, "repair_required", selection, queueError)
        return nil, queueError
    end
    commit("state", function(record)
        if selection.cooldownKey then
            record.ruleCooldowns[selection.cooldownKey] = selection.cooldownUntil
            return true
        end
        return false
    end)
    return finishReceipt(receipt.receiptId, "succeeded", selection)
end

local function processArticle(article)
    for _, rule in ipairs(ChronicleRules.Definitions) do
        if ChronicleRules.Matches(rule, article) then
            local receiptId = ChronicleState.NewsRuleReceiptId(
                article.articleId, article.revision, rule.ruleId)
            local receipt = self.records.receipts.receipts[receiptId]
            if not receipt then
                local selection, selectionError = ChronicleRules.Evaluate(
                    rule, article, self.records.state.ruleCooldowns, now())
                if not selection then return nil, selectionError end
                receipt, selectionError = prepareRuleReceipt(article, rule, selection)
                if not receipt then return nil, selectionError end
            end
            if receipt.state == "prepared" then
                local _, resultError = materializeRuleSelection(article, rule, receipt)
                if resultError and resultError ~= "coordinate_conflict" then return nil, resultError end
            end
        end
    end
    return true
end

local function reconcileNews()
    if not self.records.state or not self.records.receipts or not self.records.events then
        return nil, "record_unavailable"
    end
    if not self.reconcileQueue then
        local built, buildError = buildReconcileQueue()
        if not built then
            setHealth("unavailable", nil, buildError)
            return nil, buildError
        end
    end
    local processed = 0
    while #self.reconcileQueue > 0 and processed < RECONCILE_ARTICLES_PER_TICK do
        local article = table.remove(self.reconcileQueue, 1)
        local ok, articleError = processArticle(article)
        if not ok then
            setHealth("degraded", nil, articleError)
            commit("state", function(record)
                record.health.reconciliationFailures =
                    (record.health.reconciliationFailures or 0) + 1
                return true
            end)
            return nil, articleError
        end
        processed = processed + 1
    end
    if #self.reconcileQueue == 0 then
        local target = self.reconcileTarget or {feedRevision = 0, latestSequence = 0}
        commit("state", function(record)
            record.sourceCursors.newsRevision = target.feedRevision
            record.sourceCursors.latestSequence = target.latestSequence
            record.health.newsManager = "healthy"
            record.health.lastSuccessfulReconcileAt = now()
            record.scheduler.nextReconcileAt = now() + RECONCILE_INTERVAL
            record.lastError = nil
            return true
        end)
        self.reconcileQueue = nil
        self.reconcileTarget = nil
    end
    return true
end

function ChronicleCoordinator.initialize()
    if not onServer() then return end
    for _, name in ipairs({"state", "events", "receipts", "repairs"}) do loadRecord(name) end
    if self.records.state and type(self.records.state.externalEvents) ~= "table" then
        commit("state", function(record) record.externalEvents = {} return true end)
    end
    ChronicleGoods.RegisterAll()
    local rulesValid, rulesError = ChronicleRules.Validate(ChronicleRules.Definitions)
    if not rulesValid then
        self.blocked.rules = rulesError
        setHealth("degraded", "degraded", rulesError)
        return
    end
    Server():registerCallback("onCosmicVaultNewsChanged", "onCosmicVaultNewsChanged")
    Galaxy():registerCallback("onBehemothAttackStart", "onBehemothAttackStart")
    registerVaultContracts()
    performMigration()
end

function ChronicleCoordinator.onBehemothAttackStart(quadrant, x, y)
    if type(quadrant) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return end
    local identity = table.concat({"behemoth", quadrant, x, y,
        math.floor(now() / 60)}, ":")
    commit("state", function(record)
        record.externalEvents.behemoth = {identity = identity, quadrant = quadrant,
            x = x, y = y, state = "active", startedAt = now()}
        return true
    end)
    ChronicleNews.PublishObservation({kind = "behemoth", identity = identity,
        eventType = "chronicles.observation.behemoth.started", topic = "threat",
        category = "Galactic Threat", severity = "critical", breaking = true,
        title = "Behemoth Assault Detected",
        content = "A Behemoth assault has begun. Independent captains are advised to respond immediately.",
        location = {x = x, y = y}, lead = {kind = "location", x = x, y = y},
        provenance = {recordType = "vanilla_behemoth_callback", sourceRevision = 0,
            sourceState = "started", quadrant = quadrant}})
end

function ChronicleCoordinator.resolveBehemoth(owner, x, y, entityId, destroyerId)
    if owner ~= "data/scripts/entity/cc_behemoth_tracker.lua"
            or type(x) ~= "number" or type(y) ~= "number"
            or type(entityId) ~= "string" or type(destroyerId) ~= "string" then
        return nil, "invalid_arguments"
    end
    local active = self.records.state and self.records.state.externalEvents.behemoth
    if not active or active.state ~= "active" or active.x ~= x or active.y ~= y then
        return nil, "not_found"
    end
    local resolved = commit("state", function(record)
        local current = record.externalEvents.behemoth
        if not current or current.state ~= "active" then return false end
        current.state = "resolved"
        current.entityId = entityId
        current.destroyerId = destroyerId
        current.resolvedAt = now()
        return true
    end)
    if not resolved then return nil, "store_failed" end
    ChronicleNews.ResolveObservation("behemoth", active.identity,
        {kind = "destroyed", entityId = entityId, destroyerId = destroyerId}, "resolved")
    return copy(self.records.state.externalEvents.behemoth), nil
end

function ChronicleCoordinator.publishObservedEvent(owner, observation)
    if owner ~= "player_controller" and owner ~= "sector_observer" then
        return nil, "wrong_owner"
    end
    if type(observation) ~= "table" or type(observation.identity) ~= "string"
            or type(observation.kind) ~= "string" then return nil, "invalid_arguments" end
    return ChronicleNews.PublishObservation(observation)
end

function ChronicleCoordinator.getUpdateInterval()
    return 2
end

function ChronicleCoordinator.updateServer(timeStep)
    if self.registrationDue then registerVaultContracts() end
    if self.migrationDue then performMigration() end
    if self.blocked.rules then return end
    local state = self.records.state
    if not state then return end
    if next(self.pendingArticleIds) or self.reconcileQueue
            or now() >= (state.scheduler.nextReconcileAt or 0) then
        reconcileNews()
    end
end

function ChronicleCoordinator.onCosmicVaultNewsChanged(feedRevision, articleId, changeType)
    if type(articleId) == "string" then self.pendingArticleIds[articleId] = true end
end

function ChronicleCoordinator.getSnapshot()
    local state = self.records.state
    local events = self.records.events
    local receipts = self.records.receipts
    if not state or not events or not receipts then return nil, "record_unavailable" end
    local eventStates = {}
    for _, event in pairs(events.events) do
        eventStates[event.state] = (eventStates[event.state] or 0) + 1
    end
    local receiptStates = {}
    for _, receipt in pairs(receipts.receipts) do
        receiptStates[receipt.state] = (receiptStates[receipt.state] or 0) + 1
    end
    return {
        schemaVersion = 2,
        stateRevision = state.revision,
        eventsRevision = events.revision,
        receiptsRevision = receipts.revision,
        migration = copy(state.migration),
        sourceCursors = copy(state.sourceCursors),
        health = copy(state.health),
        eventStates = eventStates,
        receiptStates = receiptStates,
        blocked = copy(self.blocked),
        repairRequired = state.repairRequired,
        lastError = state.lastError,
    }, nil
end

function ChronicleCoordinator.getEventForSector(x, y)
    local key, coordinateError = ChronicleState.CoordinateKey(x, y)
    if not key then return nil, coordinateError end
    local matches = {}
    for _, event in pairs(self.records.events and self.records.events.events or {}) do
        if event.x == x and event.y == y and not TERMINAL_EVENTS[event.state] then
            matches[#matches + 1] = copy(event)
        end
    end
    table.sort(matches, function(left, right) return left.eventId < right.eventId end)
    if #matches == 0 then return nil, "not_found" end
    if #matches > 1 then return nil, "repair_required" end
    return matches[1], nil
end

function ChronicleCoordinator.getEvent(eventId)
    if type(eventId) ~= "string" then return nil, "invalid_arguments" end
    local event = self.records.events and self.records.events.events[eventId]
    return event and copy(event) or nil, event and nil or "not_found"
end

function ChronicleCoordinator.queueDerivedEvent(owner, parentEventId, eventType, x, y,
        discriminator, triggerEvidence)
    local allowedOwners = {
        ["data/scripts/entity/cc_refugeedialogue.lua"] = true,
        ["data/scripts/entity/cc_blackbox.lua"] = true,
    }
    if not allowedOwners[owner] or type(parentEventId) ~= "string"
            or type(eventType) ~= "string" or type(triggerEvidence) ~= "table" then
        return nil, "invalid_arguments"
    end
    local parent = self.records.events and self.records.events.events[parentEventId]
    if not parent then return nil, "parent_not_found" end
    local derivedId, idError = ChronicleState.MakeEventId(eventType, x, y,
        tostring(discriminator or parentEventId))
    if not derivedId then return nil, idError end
    local event, eventError = createEvent({eventId = derivedId, eventType = eventType,
        x = x, y = y, seed = tonumber(triggerEvidence.seed) or 0,
        expiresAt = triggerEvidence.expiresAt,
        trigger = {kind = "derived_interaction", parentEventId = parentEventId,
            evidence = triggerEvidence}})
    if not event then return nil, eventError end
    if event.state == "pending" then return queueEvent(event) end
    return event, nil, false
end

function ChronicleCoordinator.requestEventTransition(owner, eventId, expectedRevision,
        nextState, evidence)
    local allowedOwners = {sector_observer = true, event_materializer = true,
        event_resolver = true, repair = true}
    if not allowedOwners[owner] or type(eventId) ~= "string"
            or type(expectedRevision) ~= "number" or type(evidence) ~= "table" then
        return nil, "invalid_arguments"
    end
    local event = self.records.events and self.records.events.events[eventId]
    if not event then return nil, "not_found" end
    if event.revision ~= expectedRevision then return nil, "stale_revision" end
    local transitioned, transitionError = mutateEvent(eventId, function(current)
        local transitioned, transitionError = ChronicleState.Transition(current, nextState,
            ChronicleState.EVENT_TRANSITIONS, {outcome = evidence.outcome,
                lastError = evidence.lastError,
                repairRequired = evidence.repairRequired,
                materialization = evidence.materialization or current.materialization,
                participants = evidence.participants or current.participants}, now())
        if not transitioned then return nil, transitionError end
        for key, value in pairs(transitioned) do current[key] = value end
        current.revision = expectedRevision
        return true
    end)
    if not transitioned then return nil, transitionError end
    if TERMINAL_EVENTS[transitioned.state] then
        ChronicleNews.ResolveEvent(transitioned)
    elseif transitioned.state == "active" or transitioned.state == "resolving" then
        ChronicleNews.UpsertEvent(transitioned)
    end
    return transitioned, nil
end

function ChronicleCoordinator.recordLoadedSectorLegacyEvidence(x, y, evidence)
    if type(evidence) ~= "table" then return nil, "invalid_arguments" end
    local coordinateKey, coordinateError = ChronicleState.CoordinateKey(x, y)
    if not coordinateKey then return nil, coordinateError end
    local tombstoneId = "legacy:" .. coordinateKey
    local stored, storeError = commit("events", function(record)
        local existing = record.tombstones[tombstoneId]
        local changed = false
        if not existing then
            record.tombstones[tombstoneId] = {
                schemaVersion = 1,
                tombstoneId = tombstoneId,
                x = x,
                y = y,
                state = "legacy_consumed",
                evidence = copy(evidence),
                observedAt = now(),
                noReplay = true,
            }
            changed = true
        end
        if evidence.eventSpawned or evidence.bountyBossSpawned or evidence.lootTriggered then
            for _, event in pairs(record.events) do
                if event.x == x and event.y == y and not TERMINAL_EVENTS[event.state]
                        and event.trigger and event.trigger.kind == "legacy_delimiter" then
                    event.state = "repair_required"
                    event.revision = (event.revision or 0) + 1
                    event.updatedAt = now()
                    event.lastError = "legacy_sector_outcome_ambiguous"
                    event.repairRequired = "Legacy work was observed, but delivery or reward cannot be proven."
                    changed = true
                end
            end
        end
        return changed
    end)
    if not stored then return nil, storeError end
    return copy(self.records.events.tombstones[tombstoneId]), nil
end

function ChronicleCoordinator.preparePlayerMilestoneReceipt(owner, playerIndex, milestoneId,
        sourceEvidence, rewardSnapshot)
    if owner ~= "data/scripts/player/background/cc_player_controller.lua"
            or type(playerIndex) ~= "number" or playerIndex % 1 ~= 0
            or type(milestoneId) ~= "string" or type(sourceEvidence) ~= "table"
            or type(rewardSnapshot) ~= "table"
            or type(rewardSnapshot.credits) ~= "number" or rewardSnapshot.credits < 0
            or type(rewardSnapshot.reputation) ~= "number" or rewardSnapshot.reputation < 0 then
        return nil, "invalid_arguments"
    end
    local receiptId, idError = ChronicleState.PlayerMilestoneReceiptId(playerIndex, milestoneId)
    if not receiptId then return nil, idError end
    local existing = self.records.receipts and self.records.receipts.receipts[receiptId]
    if existing then return copy(existing), nil, false end
    local receipt, receiptError = ChronicleState.NewReceipt({
        receiptId = receiptId,
        operationKind = "player_milestone_bonus",
        recipient = {kind = "player", playerIndex = playerIndex},
        sourceEvidence = sourceEvidence,
    }, now())
    if not receipt then return nil, receiptError end
    receipt.resultEvidence = {rewardSnapshot = copy(rewardSnapshot)}
    local stored, storeError = commit("receipts", function(record)
        if record.receipts[receiptId] then return false end
        if count(record.receipts) >= ChronicleState.LIMITS.receipts then
            return nil, "receipt_limit_reached"
        end
        record.receipts[receiptId] = receipt
        return true
    end)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil, true
end

function ChronicleCoordinator.getReceipt(receiptId)
    if type(receiptId) ~= "string" then return nil, "invalid_arguments" end
    local receipt = self.records.receipts and self.records.receipts.receipts[receiptId]
    return receipt and copy(receipt) or nil, receipt and nil or "not_found"
end

function ChronicleCoordinator.transitionPlayerReceipt(owner, playerIndex, receiptId,
        expectedRevision, nextState, resultEvidence, errorText)
    if owner ~= "data/scripts/player/background/cc_player_controller.lua"
            or type(playerIndex) ~= "number" or type(receiptId) ~= "string"
            or type(expectedRevision) ~= "number"
            or (nextState ~= "succeeded" and nextState ~= "repair_required"
                and nextState ~= "abandoned") then return nil, "invalid_arguments" end
    local receipt = self.records.receipts and self.records.receipts.receipts[receiptId]
    if not receipt then return nil, "not_found" end
    if receipt.recipient.playerIndex ~= playerIndex then return nil, "wrong_recipient" end
    if receipt.revision ~= expectedRevision then return nil, "stale_revision" end
    local stored, storeError = finishReceipt(receiptId, nextState, resultEvidence,
        errorText)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil
end

function ChronicleCoordinator.prepareInteractionReceipt(owner, entityId, interactionType,
        playerIndex, sourceEvidence, resultEvidence)
    if not INTERACTION_OWNERS[owner] or type(entityId) ~= "string"
            or type(interactionType) ~= "string" or type(playerIndex) ~= "number"
            or type(sourceEvidence) ~= "table" or type(resultEvidence) ~= "table" then
        return nil, "invalid_arguments"
    end
    local discriminator = sourceEvidence.receiptDiscriminator
    if discriminator ~= nil and type(discriminator) ~= "string" then
        return nil, "invalid_arguments"
    end
    local receiptId, idError = ChronicleState.EntityInteractionReceiptId(entityId,
        interactionType, discriminator)
    if not receiptId then return nil, idError end
    local existing = self.records.receipts and self.records.receipts.receipts[receiptId]
    if existing then return copy(existing), nil, false end
    local receipt, receiptError = ChronicleState.NewReceipt({
        receiptId = receiptId,
        operationKind = "entity_interaction",
        recipient = {kind = "player", playerIndex = playerIndex},
        sourceEvidence = sourceEvidence,
    }, now())
    if not receipt then return nil, receiptError end
    receipt.resultEvidence = resultEvidence
    local stored, storeError = commit("receipts", function(record)
        if record.receipts[receiptId] then return false end
        if count(record.receipts) >= ChronicleState.LIMITS.receipts then
            return nil, "receipt_limit_reached"
        end
        record.receipts[receiptId] = receipt
        return true
    end)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil, true
end

function ChronicleCoordinator.transitionInteractionReceipt(owner, playerIndex, receiptId,
        expectedRevision, nextState, resultEvidence, errorText)
    if not INTERACTION_OWNERS[owner] or type(playerIndex) ~= "number"
            or type(receiptId) ~= "string" or type(expectedRevision) ~= "number" then
        return nil, "invalid_arguments"
    end
    local receipt = self.records.receipts and self.records.receipts.receipts[receiptId]
    if not receipt or receipt.operationKind ~= "entity_interaction" then return nil, "not_found" end
    if receipt.recipient.playerIndex ~= playerIndex then return nil, "wrong_recipient" end
    if receipt.revision ~= expectedRevision then return nil, "stale_revision" end
    if nextState ~= "succeeded" and nextState ~= "repair_required"
            and nextState ~= "abandoned" then return nil, "invalid_arguments" end
    local stored, storeError = finishReceipt(receiptId, nextState, resultEvidence, errorText)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil
end

function ChronicleCoordinator.prepareEventRewardReceipt(owner, eventId, playerIndex,
        sourceEvidence, rewardSnapshot)
    if owner ~= "event_resolver" or type(eventId) ~= "string"
            or type(playerIndex) ~= "number" or playerIndex % 1 ~= 0
            or type(sourceEvidence) ~= "table" or type(rewardSnapshot) ~= "table" then
        return nil, "invalid_arguments"
    end
    local event = self.records.events and self.records.events.events[eventId]
    if not event then return nil, "not_found" end
    local receiptId, idError = ChronicleState.PlayerEventReceiptId(playerIndex, eventId)
    if not receiptId then return nil, idError end
    local existing = self.records.receipts and self.records.receipts.receipts[receiptId]
    if existing then return copy(existing), nil, false end
    local receipt, receiptError = ChronicleState.NewReceipt({
        receiptId = receiptId,
        operationKind = "event_reward",
        recipient = {kind = "player", playerIndex = playerIndex},
        sourceEvidence = sourceEvidence,
    }, now())
    if not receipt then return nil, receiptError end
    receipt.resultEvidence = {rewardSnapshot = copy(rewardSnapshot)}
    local stored, storeError = commit("receipts", function(record)
        if record.receipts[receiptId] then return false end
        if count(record.receipts) >= ChronicleState.LIMITS.receipts then
            return nil, "receipt_limit_reached"
        end
        record.receipts[receiptId] = receipt
        return true
    end)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil, true
end

function ChronicleCoordinator.transitionEventRewardReceipt(owner, eventId, playerIndex,
        receiptId, expectedRevision, nextState, resultEvidence, errorText)
    if owner ~= "event_resolver" or type(eventId) ~= "string"
            or type(playerIndex) ~= "number" or type(receiptId) ~= "string"
            or type(expectedRevision) ~= "number"
            or (nextState ~= "succeeded" and nextState ~= "repair_required"
                and nextState ~= "abandoned") then return nil, "invalid_arguments" end
    local receipt = self.records.receipts and self.records.receipts.receipts[receiptId]
    if not receipt or receipt.operationKind ~= "event_reward" then return nil, "not_found" end
    if receipt.recipient.playerIndex ~= playerIndex
            or receipt.sourceEvidence.eventId ~= eventId then return nil, "wrong_recipient" end
    if receipt.revision ~= expectedRevision then return nil, "stale_revision" end
    local stored, storeError = finishReceipt(receiptId, nextState, resultEvidence, errorText)
    if not stored then return nil, storeError end
    return copy(self.records.receipts.receipts[receiptId]), nil
end

local function collectRepairFindings(scope)
    local findings = {}
    for name, errorCode in pairs(self.blocked) do
        findings[#findings + 1] = {kind = "blocked_record", itemId = name,
            evidence = tostring(errorCode), permittedActions = {"abandon"}}
    end
    if scope == "all" or scope == "events" or scope == "queues" then
        for eventId, event in pairs(self.records.events and self.records.events.events or {}) do
            if event.state == "repair_required" or event.state == "failed_permanent" then
                findings[#findings + 1] = {kind = "event", itemId = eventId,
                    evidence = tostring(event.repairRequired or event.lastError),
                    permittedActions = {"retry", "mark-complete", "abandon"},
                    observedRevision = event.revision}
            end
        end
    end
    if scope == "all" or scope == "queues" then
        local queueRecords = Territory.ListMaterializations("chronicles_event",
            {repair_required = true, failed_permanent = true}) or {}
        for _, queueRecord in ipairs(queueRecords) do
            findings[#findings + 1] = {kind = "queue", itemId = queueRecord.id,
                queueKind = "chronicles_event", x = queueRecord.x, y = queueRecord.y,
                evidence = tostring(queueRecord.repairRequired or queueRecord.lastError),
                permittedActions = {"retry", "mark-complete", "abandon"},
                observedRevision = queueRecord.revision}
        end
    end
    if scope == "all" or scope == "news" or scope == "interactions"
            or scope == "player" then
        for receiptId, receipt in pairs(self.records.receipts and self.records.receipts.receipts or {}) do
            if receipt.state == "repair_required" or receipt.state == "prepared" then
                local actions = {"mark-complete", "abandon"}
                if receipt.operationKind == "news_rule" then
                    actions = {"resume", "abandon"}
                elseif receipt.operationKind == "player_milestone_bonus" then
                    actions = {"mark-complete", "reissue", "abandon"}
                end
                findings[#findings + 1] = {kind = "receipt", itemId = receiptId,
                    evidence = tostring(receipt.repairRequired or receipt.lastError or receipt.state),
                    permittedActions = actions,
                    observedRevision = receipt.revision}
            end
        end
    end
    table.sort(findings, function(left, right)
        return tostring(left.kind) .. tostring(left.itemId)
            < tostring(right.kind) .. tostring(right.itemId)
    end)
    return findings
end

function ChronicleCoordinator.scanRepair(scope, playerIndex)
    local allowed = {all = true, news = true, player = true, events = true,
        interactions = true, dialogue = true, queues = true}
    if not allowed[scope] then return nil, "invalid_scope" end
    local scan
    local stored, storeError = commit("repairs", function(record)
        local repairId = "chronicles:" .. tostring(record.nextRepairId)
        record.nextRepairId = record.nextRepairId + 1
        scan = {
            schemaVersion = 1,
            repairId = repairId,
            scope = scope,
            playerIndex = playerIndex,
            state = "open",
            createdAt = now(),
            findings = collectRepairFindings(scope),
            observedRevisions = {
                state = self.records.state and self.records.state.revision or -1,
                events = self.records.events and self.records.events.revision or -1,
                receipts = self.records.receipts and self.records.receipts.revision or -1,
            },
        }
        record.scans[repairId] = scan
        local ids = {}
        for id, candidate in pairs(record.scans) do
            ids[#ids + 1] = {id = id, at = candidate.createdAt or 0}
        end
        table.sort(ids, function(left, right) return left.at < right.at end)
        while #ids > ChronicleState.LIMITS.repairScans do
            record.scans[ids[1].id] = nil
            table.remove(ids, 1)
        end
        return true
    end)
    if not stored then return nil, storeError end
    return copy(scan), nil
end

function ChronicleCoordinator.getRepairStatus(repairId)
    local repairs = self.records.repairs
    if not repairs then return nil, "record_unavailable" end
    if repairId then
        local scan = repairs.scans[repairId]
        return scan and copy(scan) or nil, scan and nil or "not_found"
    end
    local latest
    for _, scan in pairs(repairs.scans) do
        if not latest or (scan.createdAt or 0) > (latest.createdAt or 0) then latest = scan end
    end
    return latest and copy(latest) or nil, latest and nil or "not_found"
end

function ChronicleCoordinator.getRepairHistory(repairId)
    local result = {}
    for _, entry in ipairs(self.records.repairs and self.records.repairs.history or {}) do
        if not repairId or entry.repairId == repairId then result[#result + 1] = copy(entry) end
    end
    return result, nil
end

function ChronicleCoordinator.applyRepair(repairId, action, administratorPlayerIndex)
    local administrator = Player(administratorPlayerIndex)
    if not administrator or not Server():hasAdminPrivileges(administrator) then
        return nil, "admin_required"
    end
    local allowedActions = {resume = true, retry = true, ["mark-complete"] = true,
        reissue = true, abandon = true}
    if not allowedActions[action] then return nil, "invalid_action" end
    local scan = self.records.repairs and self.records.repairs.scans[repairId]
    if not scan or scan.state ~= "open" then return nil, "not_found" end
    if scan.observedRevisions.events ~= (self.records.events and self.records.events.revision or -1)
            or scan.observedRevisions.receipts ~= (self.records.receipts and self.records.receipts.revision or -1) then
        commit("repairs", function(record)
            record.scans[repairId].state = "stale"
            return true
        end)
        return nil, "stale_revision"
    end

    local applied = 0
    for _, finding in ipairs(scan.findings or {}) do
        local permitted = false
        for _, candidate in ipairs(finding.permittedActions or {}) do
            if candidate == action then permitted = true break end
        end
        if permitted and finding.kind == "event" then
            local nextState = action == "retry" and "retryable"
                or action == "mark-complete" and "succeeded"
                or action == "abandon" and "abandoned" or nil
            if nextState then
                local event = self.records.events.events[finding.itemId]
                if event and event.revision == finding.observedRevision then
                    -- Goes through the same validated entry point as the normal event
                    -- lifecycle, under the "repair" owner. EVENT_TRANSITIONS carries an
                    -- explicit failed_permanent escape hatch for exactly this admin path.
                    -- lastError/repairRequired are cleared to false (not omitted) so the
                    -- Transition fields loop actually overwrites the old evidence instead
                    -- of skipping a nil-valued key.
                    local changed = ChronicleCoordinator.requestEventTransition("repair",
                        finding.itemId, finding.observedRevision, nextState,
                        {lastError = false, repairRequired = false})
                    -- requestEventTransition already calls ChronicleNews.ResolveEvent for
                    -- terminal states, so no separate sync call is needed here.
                    if changed then applied = applied + 1 end
                end
            end
        elseif permitted and finding.kind == "receipt" then
            local receipt = self.records.receipts.receipts[finding.itemId]
            if receipt and receipt.revision == finding.observedRevision then
                if action == "resume" then
                    commit("receipts", function(record)
                        local current = record.receipts[finding.itemId]
                        current.state = "prepared"
                        current.lastError = nil
                        current.repairRequired = nil
                        current.revision = current.revision + 1
                        return true
                    end)
                    self.reconcileQueue = nil
                    applied = applied + 1
                elseif action == "abandon" then
                    finishReceipt(finding.itemId, "abandoned", receipt.resultEvidence,
                        "administrator_abandoned")
                    applied = applied + 1
                elseif action == "mark-complete" then
                    finishReceipt(finding.itemId, "succeeded", receipt.resultEvidence,
                        "administrator_mark_complete")
                    applied = applied + 1
                elseif action == "reissue"
                        and receipt.operationKind == "player_milestone_bonus" then
                    commit("receipts", function(record)
                        local current = record.receipts[finding.itemId]
                        current.state = "prepared"
                        current.lastError = nil
                        current.repairRequired = nil
                        current.adminReissueAuthorized = repairId
                        current.revision = current.revision + 1
                        return true
                    end)
                    local recipient = receipt.recipient and receipt.recipient.playerIndex
                    local targetPlayer = recipient and Player(recipient)
                    if targetPlayer then
                        targetPlayer:invokeFunction(
                            "data/scripts/player/background/cc_player_controller.lua",
                            "requestReceiptRecovery", "admin_reissue")
                    end
                    applied = applied + 1
                end
            end
        elseif permitted and finding.kind == "queue" then
            local queueRecord = Territory.GetMaterialization(finding.queueKind,
                finding.x, finding.y)
            if queueRecord and queueRecord.revision == finding.observedRevision then
                local result = action == "mark-complete" and {
                    repairedBy = administratorPlayerIndex, repairId = repairId,
                    evidence = "administrator_mark_complete"} or nil
                local repaired = Territory.ResolveMaterializationRepair(finding.queueKind,
                    finding.x, finding.y, action, result)
                if repaired then applied = applied + 1 end
            end
        elseif permitted and finding.kind == "blocked_record" and action == "abandon" then
            local definition = RECORDS[finding.itemId]
            if definition and self.blocked[finding.itemId] then
                local replacement = definition.constructor(now())
                local stored = Data.SetRecord(Server(), definition.key, replacement)
                if stored then
                    self.records[finding.itemId] = replacement
                    self.blocked[finding.itemId] = nil
                    if finding.itemId == "state" or finding.itemId == "events" then
                        self.migrationDue = true
                    end
                    applied = applied + 1
                end
            end
        end
    end

    commit("repairs", function(record)
        local current = record.scans[repairId]
        current.state = "applied"
        current.appliedAt = now()
        current.appliedAction = action
        current.appliedBy = administratorPlayerIndex
        appendBounded(record.history, {
            schemaVersion = 1,
            repairId = repairId,
            actor = administratorPlayerIndex,
            at = now(),
            action = action,
            result = "applied:" .. tostring(applied),
        }, ChronicleState.LIMITS.repairHistory)
        return true
    end)
    return {repairId = repairId, action = action, result = "applied:" .. tostring(applied)}, nil
end

return ChronicleCoordinator
