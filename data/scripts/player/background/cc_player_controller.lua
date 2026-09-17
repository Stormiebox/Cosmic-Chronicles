package.path = package.path .. ";data/scripts/lib/?.lua"

local Data = include("cosmicvaultdata")
local News = include("cosmicvaultnews")
local Dialogue = include("cosmicvaultdialogue")
local ChronicleState = include("cc_state")
local VanillaEvidence = include("cc_vanilla_evidence")

-- namespace ChroniclePlayerController
ChroniclePlayerController = {}
local self = ChroniclePlayerController
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local OWNER = "data/scripts/player/background/cc_player_controller.lua"
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local SECTOR_OBSERVER = "data/scripts/sector/cc_sector_observer.lua"
local LEGACY_EVENT_CONTROLLER = "data/scripts/player/background/cc_event_controller.lua"
local MAX_QUERY_PAGES = 11
local MAX_PRUNE_PER_TICK = 16

self.record = nil
self.blocked = nil
self.pendingNews = {}
self.pendingObservedScripts = {}
self.nextPruneAt = 0
self.nextLeadReconcileAt = 0
self.receiptRecoveryDue = true
self.lastBreakingChatAt = 0
self.lastRegularChatAt = 0
self.notifiedNews = {}

local function now()
    local server = Server()
    return server and server.unpausedRuntime or 0
end

local function copy(value)
    local result = ChronicleState.DeepCopy(value)
    return result
end

local function player()
    return Player()
end

local function validRecord(record)
    return type(record) == "table" and record.schemaVersion == 2
        and type(record.revision) == "number" and type(record.news) == "table"
        and type(record.leads) == "table" and type(record.recentDialogueIds) == "table"
        and type(record.vanillaEvidenceBaseline) == "table"
end

local function storeRecord(working)
    working.revision = (self.record and self.record.revision or -1) + 1
    local stored, storeError = Data.SetRecord(player(), ChronicleState.KEYS.player, working)
    if not stored then return nil, storeError end
    self.record = working
    return copy(working), nil
end

local function commit(mutator)
    if self.blocked then return nil, self.blocked end
    local working, copyError = ChronicleState.DeepCopy(self.record)
    if not working then return nil, copyError end
    local changed, mutationError = mutator(working)
    if mutationError then return nil, mutationError end
    if changed == false then return copy(self.record), nil, false end
    return storeRecord(working)
end

local function initializeRecord()
    local record, loadError = Data.GetRecord(player(), ChronicleState.KEYS.player, 2)
    if record and validRecord(record) then
        record.milestones = type(record.milestones) == "table" and record.milestones or {}
        record.news.notifications = type(record.news.notifications) == "table"
            and record.news.notifications or {}
        local defaults = {breakingChat = true, nearbyHazards = true, regularChat = false}
        local changed = false
        for key, default in pairs(defaults) do
            if type(record.news.notifications[key]) ~= "boolean" then
                record.news.notifications[key] = default
                changed = true
            end
        end
        self.record = record
        if changed then return storeRecord(record) end
        return true
    end
    if loadError ~= "missing" then
        self.blocked = loadError or "corrupt"
        return nil, self.blocked
    end
    record = ChronicleState.NewPlayer(now())
    record.vanillaEvidenceBaseline = VanillaEvidence.CaptureBaseline(player())
    record.migration.state = "complete"
    record.migration.provenance.vanillaEvidence = "legacy_outcome_unknown"
    record.migration.provenance.clientSeenArticles = "unrecoverable_imported_unread"
    self.record = {revision = -1}
    return storeRecord(record)
end

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function authorized(playerIndex)
    local owner = player()
    return owner and owner.index == playerIndex
end

local function isRead(article)
    if not article then return false end
    return article.sequence <= (self.record.news.readThroughSequence or 0)
        or self.record.news.readArticleIds[article.articleId] ~= nil
end

local function sanitizeIntent(intent)
    intent = type(intent) == "table" and intent or {}
    local query = {pageSize = math.max(1, math.min(50, math.floor(tonumber(intent.pageSize) or 30))),
        audiencePlayerIndex = player().index}
    if type(intent.beforeSequence) == "number" then
        query.beforeSequence = math.floor(intent.beforeSequence)
    end
    if type(intent.ifRevision) == "number" and not query.beforeSequence then
        query.ifRevision = math.floor(intent.ifRevision)
    end
    if type(intent.publisherId) == "string" and #intent.publisherId <= 48 then
        query.publisherIds = {[intent.publisherId] = true}
    end
    if type(intent.topic) == "string" and #intent.topic <= 32 then
        query.topics = {[intent.topic] = true}
    end
    if type(intent.threadId) == "string" and #intent.threadId <= 160 then
        query.threadId = intent.threadId
    end
    if type(intent.search) == "string" then query.search = intent.search:sub(1, 96) end
    if intent.includeArchive == true then query.includeArchive = true end
    if intent.archiveOnly == true then
        query.includeArchive = true
        query.states = {resolved = true, expired = true, withdrawn = true, corrected = true}
    else
        query.states = {active = true}
    end
    if intent.nearby == true then
        local x, y = player():getSectorCoordinates()
        if type(x) == "number" and type(y) == "number" then
            query.location = {x = x, y = y, radius = 25}
        end
    end
    return query
end

local function leadForArticle(article)
    return self.record.leads[tostring(player().index) .. ":" .. article.articleId]
end

local function decoratePage(page)
    local result = copy(page)
    local unread = 0
    for _, article in ipairs(result.items or {}) do
        article.read = isRead(article)
        article.followed = article.threadId
            and self.record.news.followedThreads[article.threadId] == true or false
        local lead = leadForArticle(article)
        article.savedLeadState = lead and lead.state or nil
        if not article.read then unread = unread + 1 end
    end
    result.pageUnreadCount = unread
    result.readThroughSequence = self.record.news.readThroughSequence or 0
    result.followedThreadCount = ChronicleState.Count(self.record.news.followedThreads)
    result.savedLeadCount = ChronicleState.Count(self.record.leads)
    return result
end

local function highestAccessibleSequence()
    local page, queryError = News.Query({pageSize = 1, includeArchive = true,
        audiencePlayerIndex = player().index})
    if not page then return nil, queryError end
    local article = page.items and page.items[1]
    return article and article.sequence or 0, nil, page.feedRevision
end

local function allAccessibleUnreadCount()
    local countUnread = 0
    local beforeSequence
    for _ = 1, MAX_QUERY_PAGES do
        local page, queryError = News.Query({pageSize = 50, includeArchive = true,
            audiencePlayerIndex = player().index, beforeSequence = beforeSequence})
        if not page then return nil, queryError end
        for _, article in ipairs(page.items or {}) do
            if not isRead(article) then countUnread = countUnread + 1 end
        end
        if not page.hasMore or not page.nextCursor then break end
        beforeSequence = page.nextCursor
    end
    return countUnread, nil
end

local function pruneReadIds()
    local ids = {}
    for articleId, sequence in pairs(self.record.news.readArticleIds) do
        ids[#ids + 1] = {articleId = articleId, sequence = sequence}
    end
    table.sort(ids, function(left, right)
        return (tonumber(left.sequence) or 0) < (tonumber(right.sequence) or 0)
    end)
    local removed = 0
    commit(function(record)
        for _, candidate in ipairs(ids) do
            if removed >= MAX_PRUNE_PER_TICK then break end
            if tonumber(candidate.sequence) <= (record.news.readThroughSequence or 0) then
                record.news.readArticleIds[candidate.articleId] = nil
                removed = removed + 1
            end
        end
        while ChronicleState.Count(record.news.readArticleIds) > ChronicleState.LIMITS.readArticleIds do
            local oldest = table.remove(ids, 1)
            if not oldest then break end
            if record.news.readArticleIds[oldest.articleId] ~= nil then
                record.news.readArticleIds[oldest.articleId] = nil
                removed = removed + 1
            end
        end
        return removed > 0
    end)
end

local function relationFactionAt(x, y)
    local controlling = Galaxy():getControllingFaction(x, y)
    if type(controlling) == "number" then return controlling end
    if controlling and type(controlling.index) == "number" then return controlling.index end
end

local function rewardSnapshot(milestone)
    local x, y = player():getSectorCoordinates()
    x, y = tonumber(x) or 0, tonumber(y) or 0
    local distance = math.max(1, math.sqrt(x * x + y * y))
    local multiplier = math.max(1, 1 + (500 - distance) / 500)
    return {
        schemaVersion = 1,
        credits = math.floor(milestone.credits * multiplier),
        reputation = math.floor(milestone.reputation * multiplier),
        factionIndex = relationFactionAt(x, y),
        x = math.floor(x),
        y = math.floor(y),
    }
end

local function processMilestone(milestone)
    if self.record.vanillaEvidenceBaseline[milestone.milestoneId]
            or self.record.milestones[milestone.milestoneId] then return end
    local observed = VanillaEvidence.Evaluate(player(), milestone)
    if not observed or not observed.confirmed then return end
    local reward = rewardSnapshot(milestone)
    local receipt, receiptError, created = invokeCoordinator("preparePlayerMilestoneReceipt",
        OWNER, player().index, milestone.milestoneId, observed.evidence, reward)
    if not receipt then
        commit(function(record)
            record.lastError = receiptError
            return true
        end)
        return
    end
    if not created then
        if receipt.state == "prepared" then
            invokeCoordinator("transitionPlayerReceipt", OWNER, player().index,
                receipt.receiptId, receipt.revision, "repair_required",
                receipt.resultEvidence, "interrupted_reward_delivery")
        end
        return
    end

    local delivered = pcall(function()
        if reward.credits > 0 then
            player():receiveWithoutNotify("Chronicle Milestone", reward.credits, {})
        end
        if reward.reputation > 0 and reward.factionIndex then
            Galaxy():changeFactionRelations(Faction(player().index),
                Faction(reward.factionIndex), reward.reputation)
        end
    end)
    if not delivered then
        invokeCoordinator("transitionPlayerReceipt", OWNER, player().index,
            receipt.receiptId, receipt.revision, "repair_required",
            receipt.resultEvidence, "reward_delivery_failed")
        return
    end
    local completed, completeError = invokeCoordinator("transitionPlayerReceipt", OWNER,
        player().index, receipt.receiptId, receipt.revision, "succeeded",
        {rewardSnapshot = reward, deliveredAt = now()})
    if completed then
        commit(function(record)
            record.milestones[milestone.milestoneId] = {
                state = "succeeded", receiptId = receipt.receiptId, completedAt = now()}
            record.lastError = nil
            return true
        end)
        player():sendChatMessage("Cosmic Chronicles", 0,
            "Chronicle milestone bonus received: %s credits.", tostring(reward.credits))
    else
        commit(function(record)
            record.repairRequired = "milestone_receipt_completion_failed"
            record.lastError = completeError
            return true
        end)
    end
end

local function recoverPreparedMilestones()
    for _, milestone in ipairs(VanillaEvidence.Milestones) do
        local receiptId = ChronicleState.PlayerMilestoneReceiptId(player().index,
            milestone.milestoneId)
        local receipt, receiptError = invokeCoordinator("getReceipt", receiptId)
        if not receipt and receiptError == "coordinator_unavailable" then return nil end
        if receipt and receipt.state == "prepared" then
            if receipt.adminReissueAuthorized then
                local reward = receipt.resultEvidence and receipt.resultEvidence.rewardSnapshot
                    or {credits = 0, reputation = 0}
                local delivered = pcall(function()
                    if (tonumber(reward.credits) or 0) > 0 then
                        player():receiveWithoutNotify("Chronicle Milestone Reissue",
                            reward.credits, {})
                    end
                    if (tonumber(reward.reputation) or 0) > 0 and reward.factionIndex then
                        Galaxy():changeFactionRelations(Faction(player().index),
                            Faction(reward.factionIndex), reward.reputation)
                    end
                end)
                if delivered then
                    local completed = invokeCoordinator("transitionPlayerReceipt", OWNER,
                        player().index, receipt.receiptId, receipt.revision, "succeeded",
                        {rewardSnapshot = reward, deliveredAt = now(),
                            adminReissueAuthorized = receipt.adminReissueAuthorized})
                    if completed then
                        commit(function(record)
                            record.milestones[milestone.milestoneId] = {state = "succeeded",
                                receiptId = receipt.receiptId, completedAt = now(),
                                adminReissue = receipt.adminReissueAuthorized}
                            return true
                        end)
                    end
                else
                    invokeCoordinator("transitionPlayerReceipt", OWNER, player().index,
                        receipt.receiptId, receipt.revision, "repair_required",
                        receipt.resultEvidence, "authorized_reissue_failed")
                end
            else
                invokeCoordinator("transitionPlayerReceipt", OWNER, player().index,
                    receipt.receiptId, receipt.revision, "repair_required",
                    receipt.resultEvidence, "interrupted_reward_delivery")
            end
        end
    end
    self.receiptRecoveryDue = false
    return true
end

function ChroniclePlayerController.requestReceiptRecovery(reason)
    if not onServer() then return nil, "server_only" end
    self.receiptRecoveryDue = true
    return true, nil
end

local function reconcileLeads()
    local changed = false
    local updates = {}
    local inspected = 0
    for leadId, lead in pairs(self.record.leads) do
        if inspected >= 8 then break end
        inspected = inspected + 1
        if lead.state == "saved" or lead.state == "visited" then
            if lead.expiresAt and lead.expiresAt <= now() then
                updates[leadId] = "expired"
            else
                local article, articleError = News.GetArticle(lead.articleId,
                    {audiencePlayerIndex = player().index})
                if article then
                    if article.state == "resolved" or article.state == "corrected" then
                        updates[leadId] = "resolved"
                    elseif article.state == "expired" then updates[leadId] = "expired"
                    elseif article.state == "withdrawn" then updates[leadId] = "abandoned" end
                elseif articleError == "not_found" then
                    updates[leadId] = "expired"
                end
            end
        end
    end
    commit(function(record)
        for leadId, state in pairs(updates) do
            local lead = record.leads[leadId]
            if lead and lead.state ~= state then
                lead.state = state
                lead.updatedAt = now()
                changed = true
            end
        end
        return changed
    end)
end

function ChroniclePlayerController.initialize()
    if not onServer() then return end
    local valid, validationError = VanillaEvidence.Validate()
    if not valid then self.blocked = validationError return end
    if not initializeRecord() then return end
    player():registerCallback("onSectorEntered", "onSectorEntered")
    player():registerCallback("onScriptAdded", "onScriptAdded")
    player():registerCallback("onScriptRemoved", "onScriptRemoved")
    Server():registerCallback("onCosmicVaultNewsChanged", "onCosmicVaultNewsChanged")
    if player():hasScript(LEGACY_EVENT_CONTROLLER) then
        player():removeScript(LEGACY_EVENT_CONTROLLER)
    end
    local sector = Sector()
    if sector then
        local x, y = sector:getCoordinates()
        sector:addScriptOnce(SECTOR_OBSERVER)
        if sector:hasScript(SECTOR_OBSERVER) then
            sector:invokeFunction(SECTOR_OBSERVER, "observePlayerEntry", player().index, x, y)
        end
    end
    recoverPreparedMilestones()
end

function ChroniclePlayerController.getUpdateInterval()
    return 2
end

function ChroniclePlayerController.updateServer(timeStep)
    if self.blocked or not self.record then return end
    if self.receiptRecoveryDue then recoverPreparedMilestones() end
    for articleId in pairs(self.pendingNews) do
        self.pendingNews[articleId] = nil
        local article = News.GetArticle(articleId, {audiencePlayerIndex = player().index})
        if article and not isRead(article)
                and article.topic ~= "weather" and article.topic ~= "rift" then
            local notificationId = article.articleId .. ":" .. tostring(article.revision)
            local notifications = self.record.news.notifications
            local x, y = player():getSectorCoordinates()
            local location = article.location
            local nearby = type(location) == "table" and type(location.x) == "number"
                and type(location.y) == "number" and type(x) == "number" and type(y) == "number"
                and (location.x - x) * (location.x - x)
                    + (location.y - y) * (location.y - y) <= 400
            local isBreaking = article.breaking == true and notifications.breakingChat == true
            local isNearbyThreat = nearby and notifications.nearbyHazards == true
                and (article.severity == "warning" or article.severity == "critical")
            local isRegular = not article.breaking and notifications.regularChat == true
            local cooldown = isBreaking and 15 or 30
            local lastChatAt = isBreaking and self.lastBreakingChatAt or self.lastRegularChatAt
            if (isBreaking or isNearbyThreat or isRegular)
                    and not self.notifiedNews[notificationId]
                    and now() - lastChatAt >= cooldown then
                local prefix = isBreaking and "BREAKING"
                    or isNearbyThreat and "NEARBY ALERT" or "REPORT"
                player():sendChatMessage("Galactic News Network", 3,
                    prefix .. ": %s", tostring(article.title))
                self.notifiedNews[notificationId] = true
                if isBreaking then self.lastBreakingChatAt = now()
                else self.lastRegularChatAt = now() end
                if ChronicleState.Count(self.notifiedNews) > 64 then self.notifiedNews = {} end
            end
        end
        break
    end
    for observationId, observation in pairs(self.pendingObservedScripts) do
        self.pendingObservedScripts[observationId] = nil
        invokeCoordinator("publishObservedEvent", "player_controller", observation)
        break
    end
    if now() >= self.nextPruneAt then
        pruneReadIds()
        self.nextPruneAt = now() + 60
    end
    if now() >= self.nextLeadReconcileAt then
        reconcileLeads()
        self.nextLeadReconcileAt = now() + 30
    end
end

function ChroniclePlayerController.onCosmicVaultNewsChanged(feedRevision, articleId, changeType)
    if type(articleId) == "string" then self.pendingNews[articleId] = true end
end

function ChroniclePlayerController.onSectorEntered(playerIndex, x, y, sectorChangeType)
    if not authorized(playerIndex) then return end
    local sector = Sector()
    if sector then
        sector:addScriptOnce(SECTOR_OBSERVER)
        if sector:hasScript(SECTOR_OBSERVER) then
            sector:invokeFunction(SECTOR_OBSERVER, "observePlayerEntry", playerIndex, x, y)
        end
    end
    commit(function(record)
        local changed = false
        for _, lead in pairs(record.leads) do
            if lead.x == x and lead.y == y and lead.state == "saved" then
                lead.state = "visited"
                lead.visitedAt = now()
                changed = true
            end
        end
        return changed
    end)
end

function ChroniclePlayerController.onScriptAdded(playerIndex, scriptIndex, scriptPath)
    if not authorized(playerIndex) or type(scriptPath) ~= "string" then return end
    local observed = {
        ["data/scripts/player/events/alienattack.lua"] = {kind = "alien_attack",
            title = "Unidentified Hostiles Detected", topic = "threat"},
        ["data/scripts/player/events/headhunter.lua"] = {kind = "headhunter",
            title = "Bounty Hunters Intercept Local Traffic", topic = "conflict"},
        ["data/scripts/player/events/spawntravellingmerchant.lua"] = {kind = "travelling_merchant",
            title = "Travelling Merchant Signal", topic = "economy"},
        ["data/scripts/events/factionattackssmugglers.lua"] = {kind = "smuggler_sting",
            title = "Security Operation Underway", topic = "threat"},
        ["data/scripts/events/pirateattack.lua"] = {kind = "pirate_attack",
            title = "Pirate Activity Reported", topic = "conflict"},
    }
    local definition = observed[scriptPath]
        or observed["data/scripts/" .. scriptPath]
    if not definition then return end
    local x, y = player():getSectorCoordinates()
    local observation = {
        kind = definition.kind,
        identity = table.concat({definition.kind, tostring(player().index),
            tostring(scriptIndex or "unknown"), tostring(math.floor(now()))}, ":"),
        eventType = "chronicles.observation." .. definition.kind .. ".started",
        topic = definition.topic, category = "Local Report", severity = "info",
        title = definition.title,
        content = "The Galactic News Network received a verified local event signal.",
        location = {x = x, y = y}, audience = {mode = "player",
            playerIndex = player().index}, provenance = {recordType = "player_script_callback",
                recordId = scriptPath, sourceRevision = 0, sourceState = "attached"},
    }
    self.pendingObservedScripts[observation.identity] = observation
end

function ChroniclePlayerController.onScriptRemoved(playerIndex, oldScriptIndex, scriptPath)
    if not authorized(playerIndex) then return end
    local milestone = VanillaEvidence.GetByScriptPath(scriptPath)
    if milestone then processMilestone(milestone) end
end

function ChroniclePlayerController.queryNews(playerIndex, intent)
    if not authorized(playerIndex) then return nil, "unauthorized" end
    if self.blocked then return nil, self.blocked end
    local page, queryError = News.Query(sanitizeIntent(intent))
    if not page then return nil, queryError end
    page = decoratePage(page)
    local unreadCount = allAccessibleUnreadCount()
    page.unreadCount = unreadCount or page.pageUnreadCount
    commit(function(record)
        if record.news.lastFeedRevision == page.feedRevision then return false end
        record.news.lastFeedRevision = page.feedRevision
        return true
    end)
    return page, nil
end

function ChroniclePlayerController.markArticleRead(playerIndex, articleId)
    if not authorized(playerIndex) or type(articleId) ~= "string" then
        return nil, "unauthorized"
    end
    local article, articleError = News.GetArticle(articleId,
        {audiencePlayerIndex = playerIndex})
    if not article then return nil, articleError end
    local stored, storeError = commit(function(record)
        if article.sequence <= record.news.readThroughSequence
                or record.news.readArticleIds[articleId] then return false end
        record.news.readArticleIds[articleId] = article.sequence
        return true
    end)
    if not stored then return nil, storeError end
    return {articleId = articleId, read = true, sequence = article.sequence}, nil
end

function ChroniclePlayerController.markAllRead(playerIndex)
    if not authorized(playerIndex) then return nil, "unauthorized" end
    local sequence, sequenceError, feedRevision = highestAccessibleSequence()
    if sequence == nil then return nil, sequenceError end
    local stored, storeError = commit(function(record)
        local changed = sequence > (record.news.readThroughSequence or 0)
        record.news.readThroughSequence = math.max(record.news.readThroughSequence or 0, sequence)
        record.news.lastFeedRevision = feedRevision or record.news.lastFeedRevision
        for articleId, articleSequence in pairs(record.news.readArticleIds) do
            if articleSequence <= record.news.readThroughSequence then
                record.news.readArticleIds[articleId] = nil
                changed = true
            end
        end
        return changed
    end)
    if not stored then return nil, storeError end
    return {readThroughSequence = self.record.news.readThroughSequence,
        feedRevision = self.record.news.lastFeedRevision}, nil
end

function ChroniclePlayerController.setThreadFollowed(playerIndex, articleId, followed)
    if not authorized(playerIndex) or type(articleId) ~= "string"
            or type(followed) ~= "boolean" then return nil, "unauthorized" end
    local article, articleError = News.GetArticle(articleId,
        {audiencePlayerIndex = playerIndex})
    if not article then return nil, articleError end
    if not article.threadId then return nil, "no_thread" end
    local stored, storeError = commit(function(record)
        if followed then
            if not record.news.followedThreads[article.threadId]
                    and ChronicleState.Count(record.news.followedThreads)
                        >= ChronicleState.LIMITS.followedThreads then
                return nil, "follow_limit_reached"
            end
            record.news.followedThreads[article.threadId] = true
        else
            record.news.followedThreads[article.threadId] = nil
        end
        return true
    end)
    if not stored then return nil, storeError end
    return {threadId = article.threadId, followed = followed}, nil
end

function ChroniclePlayerController.setLeadSaved(playerIndex, articleId, saved)
    if not authorized(playerIndex) or type(articleId) ~= "string"
            or type(saved) ~= "boolean" then return nil, "unauthorized" end
    local article, articleError = News.GetArticle(articleId,
        {audiencePlayerIndex = playerIndex})
    if not article then return nil, articleError end
    local location = article.lead or article.location
    if saved and (type(location) ~= "table" or type(location.x) ~= "number"
            or type(location.y) ~= "number") then return nil, "no_location" end
    local leadId = tostring(playerIndex) .. ":" .. articleId
    local stored, storeError = commit(function(record)
        if saved then
            if not record.leads[leadId]
                    and ChronicleState.Count(record.leads) >= ChronicleState.LIMITS.leads then
                return nil, "lead_limit_reached"
            end
            record.leads[leadId] = {
                leadId = leadId, articleId = articleId, threadId = article.threadId,
                ownerId = article.publisherId, kind = "location",
                x = math.floor(location.x), y = math.floor(location.y), state = "saved",
                savedAt = now(), expiresAt = location.expiresAt or article.expiresAt,
                lastObservedArticleRevision = article.revision,
            }
        else
            record.leads[leadId] = nil
        end
        return true
    end)
    if not stored then return nil, storeError end
    return {leadId = leadId, saved = saved,
        lead = saved and copy(self.record.leads[leadId]) or nil}, nil
end

function ChroniclePlayerController.addLeadToMap(playerIndex, articleId)
    if not authorized(playerIndex) then return nil, "unauthorized" end
    local lead = self.record.leads[tostring(playerIndex) .. ":" .. tostring(articleId)]
    if not lead then return nil, "not_found" end
    if player():getKnownSector(lead.x, lead.y) then
        return {preservedExisting = true, x = lead.x, y = lead.y}, nil
    end
    local view = SectorView()
    view:setCoordinates(lead.x, lead.y)
    view.note = "Chronicle lead: " .. tostring(articleId)
    if view.tagIconPath == "" then
        view.tagIconPath = "data/textures/icons/cc_galacticnews_rss.png"
    end
    player():addKnownSector(view)
    return {added = true, x = lead.x, y = lead.y}, nil
end

function ChroniclePlayerController.getPlayerSnapshot(playerIndex)
    if not authorized(playerIndex) then return nil, "unauthorized" end
    local unreadCount = allAccessibleUnreadCount()
    return {
        schemaVersion = 2,
        revision = self.record.revision,
        news = copy(self.record.news),
        leads = copy(self.record.leads),
        milestones = copy(self.record.milestones),
        unreadCount = unreadCount or 0,
        repairRequired = self.record.repairRequired,
        lastError = self.record.lastError,
    }, nil
end

function ChroniclePlayerController.setNotificationPreference(playerIndex, preference, enabled)
    local allowed = {breakingChat = true, nearbyHazards = true, regularChat = true}
    if not authorized(playerIndex) or not allowed[preference] or type(enabled) ~= "boolean" then
        return nil, "unauthorized"
    end
    local stored, storeError = commit(function(record)
        if record.news.notifications[preference] == enabled then return false end
        record.news.notifications[preference] = enabled
        return true
    end)
    if not stored then return nil, storeError end
    return {preference = preference, enabled = enabled,
        notifications = copy(self.record.news.notifications)}, nil
end

function ChroniclePlayerController.selectDialogue(playerIndex, category, context, seed)
    if not authorized(playerIndex) or type(category) ~= "string" or type(context) ~= "table" then
        return nil, "unauthorized"
    end
    local exclusions = {}
    for _, lineId in ipairs(self.record.recentDialogueIds) do exclusions[lineId] = true end
    local selected, selectError = Dialogue.Query(category, context,
        {excludeIds = exclusions, seed = tonumber(seed) or 0})
    if not selected and selectError == "not_found" and #self.record.recentDialogueIds > 0 then
        selected, selectError = Dialogue.Query(category, context, {seed = tonumber(seed) or 0})
    end
    if not selected then return nil, selectError end
    local stored, storeError = commit(function(record)
        record.recentDialogueIds[#record.recentDialogueIds + 1] = selected.entry.lineId
        while #record.recentDialogueIds > ChronicleState.LIMITS.recentDialogueIds do
            table.remove(record.recentDialogueIds, 1)
        end
        return true
    end)
    if not stored then return nil, storeError end
    return {lineId = selected.entry.lineId, text = selected.entry.text,
        catalogRevision = selected.catalogRevision}, nil
end

return ChroniclePlayerController
