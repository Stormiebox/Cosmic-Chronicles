package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
include("stringutility")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

self.currentNewsArray = {}

-- Maps the many free-text categories published across the Cosmic series (30+ distinct
-- strings as of this writing, e.g. "War Crime", "Trade Crisis", "Galactic Milestone") onto
-- a small, stable set of top-level groups for filtering and color-coding. Unmapped categories
-- fall back to a keyword heuristic so a new category introduced by any mod still lands
-- somewhere sensible instead of being invisible to the filter.
local CATEGORY_GROUPS = {
    ["Conflict"] = "War & Conflict", ["War"] = "War & Conflict", ["War Update"] = "War & Conflict",
    ["War Casualties"] = "War & Conflict", ["War Crime"] = "War & Conflict", ["War Heat Escalation"] = "War & Conflict",
    ["Galactic War"] = "War & Conflict", ["Bounty Board"] = "War & Conflict", ["Bounty Hunters"] = "War & Conflict",
    ["Military"] = "War & Conflict", ["Eclipse Invasion"] = "War & Conflict",

    ["Economy"] = "Economy", ["Trade"] = "Economy", ["Trading"] = "Economy", ["Trade Crisis"] = "Economy",
    ["Market Watch"] = "Economy", ["Consumer"] = "Economy", ["Factory"] = "Economy",

    ["Galactic Threat"] = "Threats & Crises", ["Galactic Dread"] = "Threats & Crises", ["Crisis"] = "Threats & Crises",
    ["Illegal"] = "Threats & Crises",

    ["Galactic Milestone"] = "Discoveries & Milestones", ["Discovery"] = "Discoveries & Milestones",
    ["Exploration"] = "Discoveries & Milestones", ["Lore Anomaly"] = "Discoveries & Milestones",
    ["Galactic Expansion"] = "Discoveries & Milestones", ["Heroic Victories"] = "Discoveries & Milestones",

    ["Captain Feats"] = "Captain Stories",

    ["Politics"] = "Politics", ["Humanitarian"] = "Politics",
}

local GROUP_ORDER = { "War & Conflict", "Economy", "Threats & Crises", "Discoveries & Milestones", "Captain Stories", "Politics", "General" }

local GROUP_KEYWORDS = {
    { "War & Conflict", { "war", "conflict", "military", "bount" } },
    { "Economy", { "econom", "trade", "market", "consum", "factory" } },
    { "Threats & Crises", { "threat", "dread", "crisis", "illegal" } },
    { "Discoveries & Milestones", { "discov", "explor", "lore", "milestone", "expansion", "heroic" } },
    { "Captain Stories", { "captain" } },
    { "Politics", { "polit", "humanitar" } },
}

local function getCategoryGroup(category)
    category = category or "General"
    local mapped = CATEGORY_GROUPS[category]
    if mapped then return mapped end

    local lower = string.lower(category)
    for _, entry in ipairs(GROUP_KEYWORDS) do
        local group, keywords = entry[1], entry[2]
        for _, kw in ipairs(keywords) do
            if string.find(lower, kw, 1, true) then return group end
        end
    end
    return "General"
end

local GROUP_COLORS = {
    ["War & Conflict"] = ColorRGB(1.0, 0.35, 0.35),
    ["Economy"] = ColorRGB(1.0, 0.85, 0.2),
    ["Threats & Crises"] = ColorRGB(1.0, 0.5, 0.1),
    ["Discoveries & Milestones"] = ColorRGB(0.3, 0.8, 1.0),
    ["Captain Stories"] = ColorRGB(0.7, 0.5, 1.0),
    ["Politics"] = ColorRGB(0.3, 1.0, 0.85),
    ["General"] = ColorRGB(0.8, 0.8, 0.8),
}

local function formatAge(ageSeconds)
    ageSeconds = math.max(0, math.floor(ageSeconds or 0))
    if ageSeconds < 60 then return "Just now"%_t end
    if ageSeconds < 3600 then return string.format("%dm"%_t, math.floor(ageSeconds / 60)) end
    if ageSeconds < 86400 then return string.format("%dh"%_t, math.floor(ageSeconds / 3600)) end
    return string.format("%dd"%_t, math.floor(ageSeconds / 86400))
end

-- A stable-enough identity for session-local "have I seen this" tracking. Articles have no
-- server-assigned id, but title+timestamp is unique in practice (timestamp is assigned once,
-- server-side, at publish time and never changes).
local function articleKey(article)
    return tostring(article.title) .. "@" .. tostring(article.timestamp)
end

-- ==========================================
-- CLIENT SIDE
-- ==========================================
if onClient() then

local seenArticles = {}
local displayedList = {} -- index -> article, matches the currently visible (filtered) rows

function CosmicChroniclesNewsBoard.initialize()
    local menu = PlayerWindow()
    self.tab = menu:createTab("Galactic News"%_t, "data/textures/icons/cc_galacticnews_rss.png", "Galactic News"%_t)
    self.tab.onShowFunction = "onShowWindow"
    self.tab.onSelectedFunction = "onShowWindow"

    local outerSplit = UIHorizontalSplitter(Rect(self.tab.size), 5, 5, 0.16)
    local margin = 10
    local topWidth = outerSplit.top.width
    local topHeight = outerSplit.top.height

    local row1Bottom = topHeight * 0.34
    local row2Top = topHeight * 0.38
    local row2Bottom = topHeight * 0.68
    local row3Top = topHeight * 0.72
    local row3Bottom = topHeight - 4

    -- Row 1: title (left) + unread count (right)
    self.tab:createLabel(Rect(margin, 2, margin + 260, row1Bottom), "Galactic News Network"%_t, 20)
    self.unreadLabel = self.tab:createLabel(Rect(topWidth * 0.55, 2, topWidth - margin, row1Bottom), "", 15)
    self.unreadLabel:setTopLeftAligned()

    -- Row 2: category filter, search box, refresh -- fixed left-to-right spacing
    self.filterComboBox = self.tab:createValueComboBox(Rect(margin, row2Top, margin + 220, row2Bottom), "onFilterChanged")
    self.filterComboBox:addEntry("All", "All Categories"%_t)
    for _, group in ipairs(GROUP_ORDER) do
        self.filterComboBox:addEntry(group, group%_t)
    end
    self.filterComboBox.tooltip = "Filter by category"%_t

    self.searchBox = self.tab:createTextBox(Rect(margin + 235, row2Top, margin + 455, row2Bottom), "onSearchTextChanged")
    self.searchBox.backgroundText = "Search headlines..."%_t

    self.refreshButton = self.tab:createButton(Rect(margin + 470, row2Top, margin + 590, row2Bottom), "Refresh"%_t, "onRefreshClicked")

    -- Row 3: breaking-news banner (hidden unless there's an unread breaking article)
    self.breakingButton = self.tab:createButton(Rect(margin, row3Top, topWidth - margin, row3Bottom), "", "onBreakingClicked")
    self.breakingButton.visible = false

    local split = UIVerticalSplitter(Rect(vec2(0, outerSplit.bottom.lower.y), self.tab.size), 10, 0, 0.35)

    self.headlineList = self.tab:createListBoxEx(split.left)
    self.headlineList.columns = 3
    self.headlineList.rowHeight = 32
    self.headlineList.headline = true
    self.headlineList.onSelectFunction = "onNewsSelected"

    local listWidth = split.left.width - 20
    self.headlineList:setColumnWidth(0, listWidth * 0.30)
    self.headlineList:setColumnWidth(1, listWidth * 0.55)
    self.headlineList:setColumnWidth(2, listWidth * 0.15)

    self.contentTextBox = self.tab:createMultiLineTextBox(split.right)

    self.headlineList:addRow()
    self.headlineList:setEntryNoCallback(0, 0, "Category"%_t, true, false, ColorRGB(1, 1, 1))
    self.headlineList:setEntryNoCallback(1, 0, "Headline"%_t, true, false, ColorRGB(1, 1, 1))
    self.headlineList:setEntryNoCallback(2, 0, "Age"%_t, true, false, ColorRGB(1, 1, 1))

    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onShowWindow()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onRefreshClicked()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onFilterChanged()
    CosmicChroniclesNewsBoard.populateUI()
end

function CosmicChroniclesNewsBoard.onSearchTextChanged(textBox)
    CosmicChroniclesNewsBoard.populateUI()
end

function CosmicChroniclesNewsBoard.onBreakingClicked()
    for i, article in ipairs(self.currentNewsArray) do
        if article.breaking and not seenArticles[articleKey(article)] then
            self.filterComboBox:setSelectedValueNoCallback("All")
            self.searchBox.text = ""
            CosmicChroniclesNewsBoard.populateUI()
            CosmicChroniclesNewsBoard.selectArticle(article)
            return
        end
    end
end

function CosmicChroniclesNewsBoard.selectArticle(article)
    local displayString = "   ===== " .. (article.title or "Unknown"%_t) .. " =====\n\n"
    displayString = displayString .. "   Reported By: "%_t .. (article.author or "Unknown"%_t) .. "\n"
    displayString = displayString .. "   Galactic News Network -- "%_t .. formatAge(article.ageSeconds) .. " "%_t .. "ago"%_t .. "\n"
    displayString = displayString .. "   Category: "%_t .. (article.category or "Unknown"%_t) .. "\n\n"
    displayString = displayString .. (article.content or "")

    self.contentTextBox.text = displayString

    local key = articleKey(article)
    if not seenArticles[key] then
        seenArticles[key] = true
        CosmicChroniclesNewsBoard.populateUI()
    end
end

function CosmicChroniclesNewsBoard.onNewsSelected(index)
    if not self.headlineList then return end

    local selectedValue = self.headlineList.selectedValue
    if not selectedValue then return end

    local article = displayedList[tonumber(selectedValue)]
    if article then
        CosmicChroniclesNewsBoard.selectArticle(article)
    end
end

function CosmicChroniclesNewsBoard.updateUnreadAndBreaking()
    local unreadCount = 0
    local breakingArticle = nil

    for _, article in ipairs(self.currentNewsArray) do
        if not seenArticles[articleKey(article)] then
            unreadCount = unreadCount + 1
            if article.breaking and not breakingArticle then
                breakingArticle = article
            end
        end
    end

    if self.unreadLabel then
        if unreadCount > 0 then
            self.unreadLabel.caption = string.format("%d Unread"%_t, unreadCount)
            self.unreadLabel.color = ColorRGB(1.0, 0.85, 0.2)
        else
            self.unreadLabel.caption = "All caught up"%_t
            self.unreadLabel.color = ColorRGB(0.6, 0.6, 0.6)
        end
    end

    if self.breakingButton then
        if breakingArticle then
            self.breakingButton.visible = true
            self.breakingButton.caption = "⚠ BREAKING: "%_t .. (breakingArticle.title or "") .. " -- "%_t .. "Click to read"%_t
        else
            self.breakingButton.visible = false
        end
    end
end

function CosmicChroniclesNewsBoard.populateUI()
    if not self.headlineList then return end

    local filterGroup = self.filterComboBox and self.filterComboBox.selectedValue or "All"
    local searchText = self.searchBox and string.lower(string.trim(self.searchBox.text or "")) or ""

    displayedList = {}
    for _, article in ipairs(self.currentNewsArray) do
        local group = getCategoryGroup(article.category)
        local matchesFilter = (filterGroup == "All" or filterGroup == nil or group == filterGroup)
        local matchesSearch = true
        if searchText ~= "" then
            local haystack = string.lower((article.title or "") .. " " .. (article.content or ""))
            matchesSearch = string.find(haystack, searchText, 1, true) ~= nil
        end

        if matchesFilter and matchesSearch then
            table.insert(displayedList, article)
        end
    end

    self.headlineList:clear()
    self.headlineList:addRow()
    self.headlineList:setEntryNoCallback(0, 0, "Category"%_t, true, false, ColorRGB(1, 1, 1))
    self.headlineList:setEntryNoCallback(1, 0, "Headline"%_t, true, false, ColorRGB(1, 1, 1))
    self.headlineList:setEntryNoCallback(2, 0, "Age"%_t, true, false, ColorRGB(1, 1, 1))

    if #displayedList == 0 then
        self.headlineList:addRow("0")
        self.headlineList:setEntryNoCallback(0, 1, "", false, false, ColorRGB(0.7, 0.7, 0.7))
        self.headlineList:setEntryNoCallback(1, 1, "No matching broadcasts."%_t, false, false, ColorRGB(0.7, 0.7, 0.7))
        self.headlineList:setEntryNoCallback(2, 1, "", false, false, ColorRGB(0.7, 0.7, 0.7))
    else
        for i, article in ipairs(displayedList) do
            self.headlineList:addRow(tostring(i))
            local row = self.headlineList.rows - 1
            local group = getCategoryGroup(article.category)
            local color = GROUP_COLORS[group] or ColorRGB(0.8, 0.8, 0.8)
            local unread = not seenArticles[articleKey(article)]

            local title = article.title or ""
            if article.breaking then title = "⚠ " .. title end
            if unread then title = title .. " ●"%_t end

            self.headlineList:setEntryNoCallback(0, row, article.category or "General"%_t, false, false, color)
            self.headlineList:setEntryNoCallback(1, row, title, unread, false, unread and ColorRGB(1, 1, 1) or ColorRGB(0.75, 0.75, 0.75))
            self.headlineList:setEntryNoCallback(2, row, formatAge(article.ageSeconds), false, false, ColorRGB(0.6, 0.6, 0.6))
        end
    end

    CosmicChroniclesNewsBoard.updateUnreadAndBreaking()
end

function CosmicChroniclesNewsBoard.receiveNews(newsArray)
    self.currentNewsArray = newsArray or {}
    CosmicChroniclesNewsBoard.populateUI()
end

end -- end onClient()


-- ==========================================
-- SERVER SIDE
-- ==========================================

-- Snapshots each article's age (in seconds, as of this sync) so the client never has to
-- compare its own clock against the server's -- Client().unpausedRuntime and
-- Server().unpausedRuntime are different clocks with different origins.
local function withAges(articles)
    local now = (Server() and Server().unpausedRuntime) or 0
    local out = {}
    for i, article in ipairs(articles) do
        local copy = {}
        for k, v in pairs(article) do copy[k] = v end
        copy.ageSeconds = math.max(0, now - (article.timestamp or now))
        out[i] = copy
    end
    return out
end

function CosmicChroniclesNewsBoard.requestNewsSync()
    if not onServer() then return end

    Server():sendCallback("onCCNewsSyncRequest", callingPlayer)

    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = withAges(vaultNews)
    end

    local player = Player(callingPlayer)
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end
callable(CosmicChroniclesNewsBoard, "requestNewsSync")

function CosmicChroniclesNewsBoard.onNewsPublished()
    if not onServer() then return end
    deferredCallback(0.1, "deferredNewsSync")
end

function CosmicChroniclesNewsBoard.deferredNewsSync()
    if not onServer() then return end

    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = withAges(vaultNews)
    end

    local player = Player()
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end


return CosmicChroniclesNewsBoard
