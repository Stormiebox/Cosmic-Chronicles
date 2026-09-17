local VaultNews = include("cosmicvaultnews")
local NewsSchema = include("cosmicvaultnews_schema")

local ChronicleNews = {}

local PUBLISHER = {
    schemaVersion = 1,
    publisherId = "cosmic_chronicles",
    displayName = "Cosmic Chronicles",
    shortName = "GNN",
    color = {r = 0.45, g = 1.0, b = 0.72},
}

local MUTABLE_FIELDS = {"title", "content", "category", "topic", "severity",
    "breaking", "author", "location", "audience", "lead", "expiresAt", "provenance"}

local EVENT_COPY = {
    ancient_data_cache = {title = "Ancient Signal Located", category = "Discovery",
        topic = "discovery", content = "Researchers have isolated an ancient data signature."},
    bounty_ambush = {title = "Bounty Target Located", category = "Conflict",
        topic = "conflict", severity = "warning", content = "A notorious pirate target has been located."},
    graveyard = {title = "Battlefield Wreckage Located", category = "War Update",
        topic = "conflict", severity = "warning", content = "Fresh military wreckage and a flight recorder have been detected."},
    stranded_diplomat = {title = "Diplomatic Distress Call", category = "Politics",
        topic = "politics", severity = "warning", content = "A stranded diplomatic vessel is requesting assistance."},
    ghost_ship = {title = "Derelict Distress Signal", category = "Lore Anomaly",
        topic = "discovery", severity = "warning", content = "A repeating distress signal is transmitting from an uncrewed vessel."},
    hidden_stash = {title = "Resource Cache Located", category = "Discovery",
        topic = "discovery", content = "A refugee lead has revealed a concealed cache."},
    refugee_convoy = {title = "Refugee Convoy in Distress", category = "Humanitarian",
        topic = "humanitarian", severity = "warning", content = "A civilian convoy has escaped the frontline without enough supplies."},
    rogue_ai_probe = {title = "Rogue Probe Detected", category = "Security",
        topic = "threat", severity = "critical", content = "A fast unidentified probe is scanning local traffic."},
    cultural_monument = {title = "Cultural Monument Charted", category = "Exploration",
        topic = "discovery", content = "A monumental structure has been charted in inhabited space."},
    eclipse_lore_anomaly = {title = "Eclipse Signal Recovered", category = "Lore Anomaly",
        topic = "threat", severity = "warning", content = "Verified Eclipse activity has exposed a corrupted archive signal."},
}

local function ensurePublisher()
    local _, registerError = VaultNews.RegisterPublisher(PUBLISHER)
    return registerError == nil and true or nil, registerError
end

local function stable(raw, prefix)
    local hash, hashError = NewsSchema.StableHash(tostring(raw))
    if not hash then return nil, hashError end
    return prefix .. ":" .. hash, nil
end

local function outcomeSummary(outcome)
    if type(outcome) == "table" then return outcome.summary end
    if type(outcome) == "string" then return outcome end
end

local function build(event, state)
    local copy = EVENT_COPY[event.eventType]
    if not copy then return nil, "unsupported_event_type" end
    local eventId, idError = stable(event.eventId, "chronicle-event")
    if not eventId then return nil, idError end
    local suffix = state == "active" and " Materialized"
        or state == "resolving" and " Developing"
        or state == "succeeded" and " Resolved" or ""
    local outcome = event.outcome and event.outcome.summary
    return {
        schemaVersion = 2,
        publisherId = "cosmic_chronicles",
        eventId = eventId,
        threadId = eventId,
        eventType = "chronicles.event." .. event.eventType .. "." .. state,
        topic = copy.topic,
        category = copy.category,
        severity = copy.severity or "info",
        breaking = copy.severity == "critical",
        title = copy.title .. suffix,
        content = outcome or copy.content,
        author = "Galactic News Network",
        location = {x = event.x, y = event.y},
        audience = {mode = "galaxy"},
        lead = state == "active" and {kind = "location", x = event.x, y = event.y,
            expiresAt = event.expiresAt} or nil,
        expiresAt = event.expiresAt,
        provenance = {recordType = "cc_events_v2", recordId = event.eventId,
            sourceRevision = event.revision, sourceState = state},
    }, nil
end

function ChronicleNews.UpsertEvent(event)
    if not onServer() then return nil, "server_only" end
    if type(event) ~= "table" or type(event.eventId) ~= "string"
            or type(event.state) ~= "string" then return nil, "invalid_arguments" end
    local ready, publisherError = ensurePublisher()
    if not ready then return nil, publisherError end
    local request, requestError = build(event, event.state)
    if not request then return nil, requestError end
    local articleId = "cosmic_chronicles:" .. request.eventId
    local existing, getError = VaultNews.GetArticle(articleId)
    if not existing and getError == "not_found" then return VaultNews.Publish(request) end
    if not existing then return nil, getError end
    if existing.state ~= "active" then return existing, nil, false end
    local patch = {}
    for _, field in ipairs(MUTABLE_FIELDS) do patch[field] = request[field] end
    return VaultNews.Update(articleId, "cosmic_chronicles", existing.revision, patch)
end

function ChronicleNews.ResolveEvent(event)
    if not onServer() then return nil, "server_only" end
    if type(event) ~= "table" then return nil, "invalid_arguments" end
    local stableEventId, idError = stable(event.eventId, "chronicle-event")
    if not stableEventId then return nil, idError end
    local articleId = "cosmic_chronicles:" .. stableEventId
    local existing, getError = VaultNews.GetArticle(articleId)
    if not existing then return nil, getError end
    if existing.state ~= "active" then return existing, nil end
    local state = event.state == "expired" and "expired"
        or event.state == "abandoned" and "withdrawn" or "resolved"
    return VaultNews.Resolve(articleId, "cosmic_chronicles", existing.revision,
        {state = state, outcome = outcomeSummary(event.outcome)})
end

function ChronicleNews.PublishObservation(options)
    if not onServer() then return nil, "server_only" end
    if type(options) ~= "table" or type(options.kind) ~= "string"
            or options.identity == nil or type(options.title) ~= "string"
            or type(options.content) ~= "string" then return nil, "invalid_arguments" end
    local ready, publisherError = ensurePublisher()
    if not ready then return nil, publisherError end
    local eventId, idError = stable(options.identity, "chronicle-observation-" .. options.kind)
    if not eventId then return nil, idError end
    return VaultNews.Publish({schemaVersion = 2, publisherId = "cosmic_chronicles",
        eventId = eventId, threadId = eventId, eventType = options.eventType
            or ("chronicles.observation." .. options.kind), topic = options.topic or "general",
        category = options.category or "Galactic News", severity = options.severity or "info",
        breaking = options.breaking == true, title = options.title, content = options.content,
        author = options.author or "Galactic News Network", location = options.location,
        audience = options.audience or {mode = "galaxy"}, lead = options.lead,
        expiresAt = options.expiresAt, provenance = options.provenance or {
            recordType = "chronicle_observation", sourceRevision = options.sourceRevision or 0,
            sourceState = options.sourceState or "verified"}})
end

function ChronicleNews.ResolveObservation(kind, identity, outcome, state)
    if not onServer() then return nil, "server_only" end
    local eventId, idError = stable(identity, "chronicle-observation-" .. tostring(kind))
    if not eventId then return nil, idError end
    local articleId = "cosmic_chronicles:" .. eventId
    local existing, getError = VaultNews.GetArticle(articleId)
    if not existing then return nil, getError end
    if existing.state ~= "active" then return existing, nil end
    return VaultNews.Resolve(articleId, "cosmic_chronicles", existing.revision,
        {state = state or "resolved", outcome = outcomeSummary(outcome)})
end

return ChronicleNews
