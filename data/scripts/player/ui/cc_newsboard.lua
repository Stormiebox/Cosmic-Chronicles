package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
include("stringutility")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

local CONTROLLER = "data/scripts/player/background/cc_player_controller.lua"

if onClient() then
    self.views = {}
    self.activeView = "live"
    self.requestId = 0

    local SOURCE_NAMES = {
        cosmic_vault = "VAULT", cosmic_war = "WAR", cosmic_overhaul = "OVERHAUL",
        cosmic_chronicles = "GNN", cosmic_ascendancy = "ASCENDANCY",
    }
    local TOPIC_COLORS = {
        conflict = ColorRGB(1.0, 0.35, 0.35), economy = ColorRGB(1.0, 0.85, 0.2),
        threat = ColorRGB(1.0, 0.5, 0.1), discovery = ColorRGB(0.3, 0.8, 1.0),
        politics = ColorRGB(0.3, 1.0, 0.85), humanitarian = ColorRGB(0.5, 1.0, 0.7),
        weather = ColorRGB(0.45, 0.8, 1.0), rift = ColorRGB(0.75, 0.5, 1.0),
        captain = ColorRGB(0.7, 0.5, 1.0), general = ColorRGB(0.8, 0.8, 0.8),
    }
    local SEVERITY_LABELS = {
        info = "INFO", advisory = "ADVISORY", warning = "WARNING", critical = "CRITICAL",
    }

    local function formatAge(ageSeconds)
        local age = math.max(0, math.floor(ageSeconds or 0))
        if age < 60 then return "now" end
        if age < 3600 then return tostring(math.floor(age / 60)) .. "m" end
        if age < 86400 then return tostring(math.floor(age / 3600)) .. "h" end
        return tostring(math.floor(age / 86400)) .. "d"
    end

    local function sourceName(article)
        return SOURCE_NAMES[article.publisherId] or string.upper(article.publisherId or "UNKNOWN")
    end

    local function stateText(errorCode, view)
        local messages = {
            not_modified = "Already up to date.", manager_unavailable = "News service unavailable.",
            coordinator_unavailable = "Chronicle coordinator unavailable.",
            stale_revision = "The feed changed. Refresh and try again.",
            unauthorized = "Permission denied.", no_location = "This report has no verified location.",
            not_found = "The report is no longer retained.",
        }
        if errorCode then return messages[errorCode] or ("Unable to load: " .. tostring(errorCode)) end
        if view == "chronicle" then return "No Chronicle entries match these filters." end
        if view == "leads" then return "No saved leads." end
        return "No broadcasts match these filters."
    end

    local function addSourceEntries(combo)
        combo:addEntry("", "All Sources")
        combo:addEntry("cosmic_vault", "Cosmic Vault")
        combo:addEntry("cosmic_war", "Cosmic War")
        combo:addEntry("cosmic_overhaul", "Cosmic Overhaul")
        combo:addEntry("cosmic_chronicles", "Cosmic Chronicles")
        combo:addEntry("cosmic_ascendancy", "Cosmic Ascendancy")
    end

    local function addTopicEntries(combo)
        combo:addEntry("", "All Topics")
        for _, topic in ipairs({"conflict", "economy", "threat", "discovery", "politics",
            "humanitarian", "weather", "rift", "captain", "general"}) do
            combo:addEntry(topic, topic:gsub("^%l", string.upper))
        end
    end

    local function buildFeedView(tab, key, fixedPublisher)
        local size = tab.size
        local margin, gap = 8, 8
        local filterHeight = 34
        local sourceWidth = math.max(130, size.x * 0.15)
        local topicWidth = math.max(115, size.x * 0.13)
        local statusWidth = math.max(105, size.x * 0.11)
        local buttonWidth = math.max(95, size.x * 0.105)
        local markWidth = math.max(145, size.x * 0.15)

        local view = {key = key, items = {}, displayItems = {}, selectedArticleId = nil,
            fixedPublisher = fixedPublisher, feedRevision = nil, nextCursor = nil}
        self.views[key] = view

        local x = margin
        view.source = tab:createValueComboBox(Rect(x, margin, x + sourceWidth, margin + filterHeight),
            "onFeedFilterChanged")
        addSourceEntries(view.source)
        if fixedPublisher then view.source:setSelectedValueNoCallback(fixedPublisher) view.source.active = false end
        x = x + sourceWidth + gap
        view.topic = tab:createValueComboBox(Rect(x, margin, x + topicWidth, margin + filterHeight),
            "onFeedFilterChanged")
        addTopicEntries(view.topic)
        x = x + topicWidth + gap
        view.status = tab:createValueComboBox(Rect(x, margin, x + statusWidth, margin + filterHeight),
            "onFeedFilterChanged")
        view.status:addEntry("active", "Live")
        view.status:addEntry("nearby", "Nearby")
        view.status:addEntry("archive", "Archive")
        x = x + statusWidth + gap
        local remaining = size.x - x - margin - (buttonWidth + gap + markWidth + gap)
        view.search = tab:createTextBox(Rect(x, margin, x + math.max(120, remaining), margin + filterHeight),
            "onSearchEdited")
        view.search.backgroundText = "Search reports..."
        x = x + math.max(120, remaining) + gap
        view.refresh = tab:createButton(Rect(x, margin, x + buttonWidth, margin + filterHeight),
            "Refresh", "onRefreshClicked")
        x = x + buttonWidth + gap
        view.markAll = tab:createButton(Rect(x, margin, math.min(size.x - margin, x + markWidth),
            margin + filterHeight), "Mark All Read", "onMarkAllReadClicked")
        view.markAll.tooltip = "Marks every report currently accessible to you as read, not only this filter."

        local statusY = margin + filterHeight + 3
        view.statusLabel = tab:createLabel(Rect(margin, statusY, size.x - margin, statusY + 22),
            "Loading Galactic News Network...", 13)
        view.statusLabel.color = ColorRGB(0.55, 0.85, 0.82)

        local bodyTop = statusY + 24
        local bodyBottom = size.y - 44
        local listWidth = math.max(350, size.x * 0.38)
        view.list = tab:createListBoxEx(Rect(margin, bodyTop, listWidth, bodyBottom))
        view.list.columns = 4
        view.list.rowHeight = 30
        view.list.headline = true
        view.list.onSelectFunction = "onReportSelected"
        local usable = listWidth - margin - 16
        view.list:setColumnWidth(0, usable * 0.20)
        view.list:setColumnWidth(1, usable * 0.19)
        view.list:setColumnWidth(2, usable * 0.48)
        view.list:setColumnWidth(3, usable * 0.13)

        local detailLeft = listWidth + gap
        view.meta = tab:createLabel(Rect(detailLeft, bodyTop, size.x - margin, bodyTop + 58),
            "Select a report to read it.", 13)
        view.meta:setTopLeftAligned()
        view.body = tab:createMultiLineTextBox(Rect(detailLeft, bodyTop + 62,
            size.x - margin, bodyBottom - 40))
        local actionY = bodyBottom - 35
        local actionWidth = (size.x - margin - detailLeft - 2 * gap) / 3
        view.follow = tab:createButton(Rect(detailLeft, actionY, detailLeft + actionWidth,
            bodyBottom), "Follow Thread", "onFollowClicked")
        view.lead = tab:createButton(Rect(detailLeft + actionWidth + gap, actionY,
            detailLeft + 2 * actionWidth + gap, bodyBottom), "Save Lead", "onLeadClicked")
        view.map = tab:createButton(Rect(detailLeft + 2 * (actionWidth + gap), actionY,
            size.x - margin, bodyBottom), "Add to Map", "onMapClicked")
        view.loadOlder = tab:createButton(Rect(margin, bodyBottom + 5, listWidth,
            size.y - 5), "Load Older", "onLoadOlderClicked")
        view.loadOlder.visible = false
        return view
    end

    local function activeFeedView()
        return self.views[self.activeView]
    end

    local function queryIntent(view, older)
        local status = view.status.selectedValue or "active"
        return {
            pageSize = 30,
            beforeSequence = older and view.nextCursor or nil,
            ifRevision = (not older) and view.feedRevision or nil,
            publisherId = view.fixedPublisher or view.source.selectedValue,
            topic = view.topic.selectedValue,
            search = view.search.text,
            nearby = status == "nearby",
            includeArchive = status == "archive",
            archiveOnly = status == "archive",
        }
    end

    local function requestView(view, older)
        if not view then return end
        self.requestId = self.requestId + 1
        view.pendingRequestId = self.requestId
        view.statusLabel.caption = older and "Loading older reports..." or "Refreshing feed..."
        invokeServerFunction("requestNewsPage", self.requestId, view.key,
            queryIntent(view, older), older == true)
    end

    local function selectedArticle(view)
        if not view or not view.selectedArticleId then return nil end
        for _, article in ipairs(view.items) do
            if article.articleId == view.selectedArticleId then return article end
        end
    end

    local function renderDetail(view, article)
        if not article then
            view.meta.caption = "Select a report to read it."
            view.body.text = ""
            view.follow.active, view.lead.active, view.map.active = false, false, false
            return
        end
        local location = article.location
        local locationText = location and string.format("Sector [%d:%d], radius %d",
            location.x, location.y, location.radius or 0) or "No verified location"
        view.meta.caption = string.format("[%s] %s\n%s • %s • %s • %s",
            SEVERITY_LABELS[article.severity] or "INFO", article.title or "Untitled",
            sourceName(article), article.category or article.topic or "General",
            article.state or "active", locationText)
        local outcome = type(article.outcome) == "string"
            and ("\n\nOutcome: " .. article.outcome) or ""
        view.body.text = string.format("Reported by %s • %s ago\nThread: %s\n\n%s%s",
            article.author or "Unknown", formatAge(article.ageSeconds),
            article.threadId or "Standalone report", article.content or "", outcome)
        view.follow.active = article.threadId ~= nil
        view.follow.caption = article.followed and "Unfollow Thread" or "Follow Thread"
        local hasLocation = article.lead ~= nil or article.location ~= nil
        view.lead.active = hasLocation
        view.lead.caption = article.savedLeadState and "Remove Lead" or "Save Lead"
        view.map.active = article.savedLeadState ~= nil
    end

    local function renderList(view)
        view.list:clear()
        view.list:addRow()
        for column, label in ipairs({"Source", "Topic", "Headline", "Age"}) do
            view.list:setEntryNoCallback(column - 1, 0, label, true, false, ColorRGB(1, 1, 1))
        end
        if #view.items == 0 then
            view.list:addRow("empty")
            view.list:setEntryNoCallback(2, 1, stateText(nil, view.key), false, false,
                ColorRGB(0.65, 0.65, 0.65))
            renderDetail(view, nil)
            return
        end
        for index, article in ipairs(view.items) do
            view.list:addRow(article.articleId)
            local row = view.list.rows - 1
            local color = TOPIC_COLORS[article.topic] or TOPIC_COLORS.general
            local severity = SEVERITY_LABELS[article.severity] or "INFO"
            local headline = (article.read and "" or "• ") .. "[" .. severity .. "] "
                .. tostring(article.title or "Untitled")
            view.list:setEntryNoCallback(0, row, sourceName(article), false, false, color)
            view.list:setEntryNoCallback(1, row, article.topic or "general", false, false, color)
            view.list:setEntryNoCallback(2, row, headline, not article.read, false,
                article.read and ColorRGB(0.72, 0.72, 0.72) or ColorRGB(1, 1, 1))
            view.list:setEntryNoCallback(3, row, formatAge(article.ageSeconds), false, false,
                ColorRGB(0.62, 0.62, 0.62))
        end
        if view.selectedArticleId then view.list:selectValueNoCallback(view.selectedArticleId) end
        renderDetail(view, selectedArticle(view))
    end

    function CosmicChroniclesNewsBoard.initialize()
        local menu = PlayerWindow()
        self.tab = menu:createTab("Galactic News", "data/textures/icons/cc_galacticnews_rss.png",
            "Galactic News Network")
        self.tab.onShowFunction = "onShowWindow"
        local size = self.tab.size
        self.title = self.tab:createLabel(Rect(10, 3, size.x * 0.55, 34),
            "Galactic News Network", 20)
        self.connection = self.tab:createLabel(Rect(size.x * 0.56, 5, size.x - 10, 32),
            "Connecting...", 13)
        self.connection:setRightAligned()
        self.breaking = self.tab:createLabel(Rect(10, 35, size.x - 10, 61), "", 14)
        self.breaking.color = ColorRGB(1.0, 0.55, 0.2)

        self.subtabs = self.tab:createTabbedWindow(Rect(5, 64, size.x - 5, size.y - 5))
        local liveTab = self.subtabs:createTab("Live Feed", "", "Current reports")
        local chronicleTab = self.subtabs:createTab("Chronicle", "", "Chronicle projections")
        local leadsTab = self.subtabs:createTab("Saved Leads", "", "Personal location leads")
        liveTab.onSelectedFunction = "onLiveSelected"
        chronicleTab.onSelectedFunction = "onChronicleSelected"
        leadsTab.onSelectedFunction = "onLeadsSelected"
        buildFeedView(liveTab, "live", nil)
        buildFeedView(chronicleTab, "chronicle", "cosmic_chronicles")
        local leadSize = leadsTab.size
        self.leadsStatus = leadsTab:createLabel(Rect(10, 8, leadSize.x - 10, 35),
            "Loading saved leads...", 14)
        local preferenceWidth = (leadSize.x - 40) / 3
        self.breakingPreference = leadsTab:createButton(Rect(10, 38,
            10 + preferenceWidth, 70), "Breaking Chat: On", "onBreakingPreferenceClicked")
        self.nearbyPreference = leadsTab:createButton(Rect(20 + preferenceWidth, 38,
            20 + 2 * preferenceWidth, 70), "Nearby Alerts: On", "onNearbyPreferenceClicked")
        self.regularPreference = leadsTab:createButton(Rect(30 + 2 * preferenceWidth, 38,
            leadSize.x - 10, 70), "Regular Chat: Off", "onRegularPreferenceClicked")
        self.notificationPreferences = {breakingChat = true, nearbyHazards = true,
            regularChat = false}
        self.leadsList = leadsTab:createListBoxEx(Rect(10, 78, leadSize.x - 10, leadSize.y - 10))
        self.leadsList.columns = 3
        self.leadsList.headline = true
        self.leadsList:setColumnWidth(0, (leadSize.x - 30) * 0.2)
        self.leadsList:setColumnWidth(1, (leadSize.x - 30) * 0.55)
        self.leadsList:setColumnWidth(2, (leadSize.x - 30) * 0.25)
        requestView(self.views.live, false)
    end

    function CosmicChroniclesNewsBoard.onShowWindow()
        requestView(activeFeedView() or self.views.live, false)
    end

    function CosmicChroniclesNewsBoard.onLiveSelected()
        self.activeView = "live"
        requestView(self.views.live, false)
    end

    function CosmicChroniclesNewsBoard.onChronicleSelected()
        self.activeView = "chronicle"
        requestView(self.views.chronicle, false)
    end

    function CosmicChroniclesNewsBoard.onLeadsSelected()
        self.activeView = "leads"
        invokeServerFunction("requestPlayerSnapshot")
    end

    function CosmicChroniclesNewsBoard.onFeedFilterChanged()
        local view = activeFeedView()
        if view then view.feedRevision = nil requestView(view, false) end
    end

    function CosmicChroniclesNewsBoard.onSearchEdited()
        local view = activeFeedView()
        if view then view.statusLabel.caption = "Search changed. Press Refresh to apply." end
    end

    function CosmicChroniclesNewsBoard.onRefreshClicked()
        local view = activeFeedView()
        if view then view.feedRevision = nil requestView(view, false) end
    end

    function CosmicChroniclesNewsBoard.onLoadOlderClicked()
        requestView(activeFeedView(), true)
    end

    function CosmicChroniclesNewsBoard.onMarkAllReadClicked()
        invokeServerFunction("requestMarkAllRead")
    end

    function CosmicChroniclesNewsBoard.onReportSelected()
        local view = activeFeedView()
        if not view or not view.list.selectedValue or view.list.selectedValue == "empty" then return end
        view.selectedArticleId = tostring(view.list.selectedValue)
        local article = selectedArticle(view)
        renderDetail(view, article)
        if article and not article.read then invokeServerFunction("requestMarkRead", article.articleId) end
    end

    function CosmicChroniclesNewsBoard.onFollowClicked()
        local view = activeFeedView()
        local article = selectedArticle(view)
        if article then invokeServerFunction("requestFollow", article.articleId, not article.followed) end
    end

    function CosmicChroniclesNewsBoard.onLeadClicked()
        local view = activeFeedView()
        local article = selectedArticle(view)
        if article then
            invokeServerFunction("requestLead", article.articleId, article.savedLeadState == nil)
        end
    end

    function CosmicChroniclesNewsBoard.onMapClicked()
        local article = selectedArticle(activeFeedView())
        if article then invokeServerFunction("requestMapLead", article.articleId) end
    end

    function CosmicChroniclesNewsBoard.onBreakingPreferenceClicked()
        invokeServerFunction("requestNotificationPreference", "breakingChat",
            not self.notificationPreferences.breakingChat)
    end

    function CosmicChroniclesNewsBoard.onNearbyPreferenceClicked()
        invokeServerFunction("requestNotificationPreference", "nearbyHazards",
            not self.notificationPreferences.nearbyHazards)
    end

    function CosmicChroniclesNewsBoard.onRegularPreferenceClicked()
        invokeServerFunction("requestNotificationPreference", "regularChat",
            not self.notificationPreferences.regularChat)
    end

    function CosmicChroniclesNewsBoard.receiveNewsPage(requestId, viewKey, page, errorCode, append)
        local view = self.views[viewKey]
        if not view or requestId ~= view.pendingRequestId then return end
        if not page then
            view.statusLabel.caption = stateText(errorCode, viewKey)
            return
        end
        if append then
            for _, article in ipairs(page.items or {}) do view.items[#view.items + 1] = article end
        else
            view.items = page.items or {}
        end
        view.feedRevision = page.feedRevision
        view.nextCursor = page.nextCursor
        view.loadOlder.visible = page.hasMore == true
        view.statusLabel.caption = string.format("Revision %d • %d unread • %d report(s) shown",
            page.feedRevision or 0, page.unreadCount or 0, #view.items)
        self.connection.caption = "Connected • " .. tostring(page.unreadCount or 0) .. " unread"
        local breaking
        for _, article in ipairs(view.items) do
            if article.breaking and not article.read then breaking = article break end
        end
        self.breaking.caption = breaking and ("BREAKING — " .. tostring(breaking.title)) or ""
        renderList(view)
    end

    function CosmicChroniclesNewsBoard.receiveMutation(result, errorCode)
        local view = activeFeedView()
        if errorCode then
            if view then view.statusLabel.caption = stateText(errorCode, view.key) end
            return
        end
        if result and result.notifications then
            self.notificationPreferences = result.notifications
            self.breakingPreference.caption = "Breaking Chat: "
                .. (result.notifications.breakingChat and "On" or "Off")
            self.nearbyPreference.caption = "Nearby Alerts: "
                .. (result.notifications.nearbyHazards and "On" or "Off")
            self.regularPreference.caption = "Regular Chat: "
                .. (result.notifications.regularChat and "On" or "Off")
        end
        if view then view.feedRevision = nil requestView(view, false) end
        if self.activeView == "leads" then invokeServerFunction("requestPlayerSnapshot") end
    end

    function CosmicChroniclesNewsBoard.receivePlayerSnapshot(snapshot, errorCode)
        self.leadsList:clear()
        self.leadsList:addRow()
        self.leadsList:setEntryNoCallback(0, 0, "Source", true, false, ColorRGB(1, 1, 1))
        self.leadsList:setEntryNoCallback(1, 0, "Location", true, false, ColorRGB(1, 1, 1))
        self.leadsList:setEntryNoCallback(2, 0, "Status", true, false, ColorRGB(1, 1, 1))
        if not snapshot then self.leadsStatus.caption = stateText(errorCode, "leads") return end
        local notifications = snapshot.news and snapshot.news.notifications or {}
        self.notificationPreferences = {
            breakingChat = notifications.breakingChat ~= false,
            nearbyHazards = notifications.nearbyHazards ~= false,
            regularChat = notifications.regularChat == true,
        }
        self.breakingPreference.caption = "Breaking Chat: "
            .. (self.notificationPreferences.breakingChat and "On" or "Off")
        self.nearbyPreference.caption = "Nearby Alerts: "
            .. (self.notificationPreferences.nearbyHazards and "On" or "Off")
        self.regularPreference.caption = "Regular Chat: "
            .. (self.notificationPreferences.regularChat and "On" or "Off")
        local leadCount = 0
        for _, lead in pairs(snapshot.leads or {}) do
            leadCount = leadCount + 1
            self.leadsList:addRow(lead.leadId)
            local row = self.leadsList.rows - 1
            self.leadsList:setEntryNoCallback(0, row, SOURCE_NAMES[lead.ownerId] or lead.ownerId,
                false, false, ColorRGB(0.55, 0.85, 0.82))
            self.leadsList:setEntryNoCallback(1, row,
                string.format("Sector [%d:%d]", lead.x, lead.y), false, false, ColorRGB(1, 1, 1))
            self.leadsList:setEntryNoCallback(2, row, lead.state or "saved", false, false,
                ColorRGB(0.75, 0.75, 0.75))
        end
        self.leadsStatus.caption = leadCount == 0 and stateText(nil, "leads")
            or tostring(leadCount) .. " saved lead(s)."
    end
end

if onServer() then
    local unpackValues = table.unpack or unpack

    local function packValues(...)
        return {n = select("#", ...), ...}
    end

    local function invokeController(functionName, ...)
        local values = packValues(Player():invokeFunction(CONTROLLER, functionName, ...))
        if values[1] ~= 0 then return nil, "controller_unavailable" end
        return unpackValues(values, 2, values.n)
    end

    local function caller()
        local target = Player(callingPlayer)
        if not target or target.index ~= Player().index then return nil end
        return target
    end

    function CosmicChroniclesNewsBoard.initialize()
    end

    function CosmicChroniclesNewsBoard.requestNewsPage(requestId, viewKey, intent, append)
        local target = caller()
        if not target then return end
        local page, errorCode = invokeController("queryNews", target.index, intent)
        invokeClientFunction(target, "receiveNewsPage", requestId, viewKey, page, errorCode,
            append == true)
    end

    function CosmicChroniclesNewsBoard.requestMarkRead(articleId)
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("markArticleRead", target.index, articleId)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestMarkAllRead()
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("markAllRead", target.index)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestFollow(articleId, followed)
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("setThreadFollowed", target.index,
            articleId, followed == true)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestLead(articleId, saved)
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("setLeadSaved", target.index,
            articleId, saved == true)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestMapLead(articleId)
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("addLeadToMap", target.index, articleId)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestPlayerSnapshot()
        local target = caller()
        if not target then return end
        local snapshot, errorCode = invokeController("getPlayerSnapshot", target.index)
        invokeClientFunction(target, "receivePlayerSnapshot", snapshot, errorCode)
    end

    function CosmicChroniclesNewsBoard.requestNotificationPreference(preference, enabled)
        local target = caller()
        if not target then return end
        local result, errorCode = invokeController("setNotificationPreference", target.index,
            preference, enabled == true)
        invokeClientFunction(target, "receiveMutation", result, errorCode)
    end

    callable(CosmicChroniclesNewsBoard, "requestNewsPage")
    callable(CosmicChroniclesNewsBoard, "requestMarkRead")
    callable(CosmicChroniclesNewsBoard, "requestMarkAllRead")
    callable(CosmicChroniclesNewsBoard, "requestFollow")
    callable(CosmicChroniclesNewsBoard, "requestLead")
    callable(CosmicChroniclesNewsBoard, "requestMapLead")
    callable(CosmicChroniclesNewsBoard, "requestPlayerSnapshot")
    callable(CosmicChroniclesNewsBoard, "requestNotificationPreference")
end

return CosmicChroniclesNewsBoard
