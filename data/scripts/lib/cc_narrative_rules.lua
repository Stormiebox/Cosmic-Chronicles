local NewsSchema = include("cosmicvaultnews_schema")

local ChronicleRules = {}

ChronicleRules.Definitions = {
    {
        schemaVersion = 1,
        ruleId = "war-aftermath-graveyard",
        publisherIds = {cosmic_war = true},
        eventTypePrefixes = {"war.battle.", "war.aftermath.", "war.siege."},
        articleStates = {active = true, resolved = true},
        requiresLocation = true,
        probability = 0.35,
        cooldownFamily = "war_aftermath",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "graveyard",
        expirySeconds = 4 * 60 * 60,
    },
    {
        schemaVersion = 1,
        ruleId = "war-humanitarian-refugees",
        publisherIds = {cosmic_war = true},
        eventTypePrefixes = {"war.humanitarian.", "war.retreat."},
        articleStates = {active = true, resolved = true},
        requiresLocation = true,
        probability = 0.30,
        cooldownFamily = "humanitarian",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "refugee_convoy",
        expirySeconds = 3 * 60 * 60,
    },
    {
        schemaVersion = 1,
        ruleId = "economy-hidden-cache",
        publisherIds = {cosmic_vault = true, cosmic_overhaul = true},
        eventTypePrefixes = {"economy.market.", "economy.famine.", "overhaul.factory."},
        articleStates = {active = true},
        requiresLocation = true,
        probability = 0.20,
        cooldownFamily = "economy_cache",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "hidden_stash",
        expirySeconds = 3 * 60 * 60,
    },
    {
        schemaVersion = 1,
        ruleId = "weather-research-signal",
        publisherIds = {cosmic_vault = true, cosmic_overhaul = true},
        eventTypePrefixes = {"weather.", "overhaul.weather."},
        articleStates = {active = true},
        requiresLocation = true,
        probability = 0.15,
        cooldownFamily = "weather_research",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "rogue_ai_probe",
        expirySeconds = 2 * 60 * 60,
    },
    {
        schemaVersion = 1,
        ruleId = "rift-ghost-signal",
        publisherIds = {cosmic_vault = true, cosmic_war = true},
        eventTypePrefixes = {"rift.", "war.rift."},
        articleStates = {active = true, resolved = true},
        requiresLocation = true,
        probability = 0.20,
        cooldownFamily = "rift_signal",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "ghost_ship",
        expirySeconds = 2 * 60 * 60,
    },
    {
        schemaVersion = 1,
        ruleId = "ascendancy-lore-anomaly",
        publisherIds = {cosmic_ascendancy = true},
        eventTypePrefixes = {"ascendancy.eclipse.", "ascendancy.world_eater.",
            "ascendancy.citadel.", "ascendancy.territory."},
        articleStates = {active = true, resolved = true},
        requiresLocation = true,
        probability = 0.15,
        cooldownFamily = "ascendancy_lore",
        cooldownSeconds = 60 * 60,
        outputType = "event",
        eventType = "eclipse_lore_anomaly",
        expirySeconds = 4 * 60 * 60,
    },
}

local OUTPUT_TYPES = {event = true, article = true, rumor = true}

local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge
        and value ~= -math.huge
end

local function nonEmptySet(values)
    if type(values) ~= "table" then return false end
    local count = 0
    for key, enabled in pairs(values) do
        if type(key) ~= "string" or enabled ~= true then return false end
        count = count + 1
    end
    return count > 0
end

function ChronicleRules.Validate(definitions)
    if type(definitions) ~= "table" then return nil, "invalid_rules" end
    local seen = {}
    for index, rule in ipairs(definitions) do
        if type(rule) ~= "table" or rule.schemaVersion ~= 1
                or type(rule.ruleId) ~= "string" or rule.ruleId == ""
                or seen[rule.ruleId] then return nil, "invalid_rule_" .. tostring(index) end
        if not nonEmptySet(rule.publisherIds) or type(rule.eventTypePrefixes) ~= "table"
                or #rule.eventTypePrefixes < 1 or not nonEmptySet(rule.articleStates)
                or not finite(rule.probability) or rule.probability < 0 or rule.probability > 1
                or type(rule.cooldownFamily) ~= "string" or rule.cooldownFamily == ""
                or not finite(rule.cooldownSeconds) or rule.cooldownSeconds < 0
                or not OUTPUT_TYPES[rule.outputType]
                or type(rule.eventType) ~= "string" or rule.eventType == ""
                or not finite(rule.expirySeconds) or rule.expirySeconds <= 0 then
            return nil, "invalid_rule_" .. tostring(index)
        end
        for _, prefix in ipairs(rule.eventTypePrefixes) do
            if type(prefix) ~= "string" or prefix == "" then
                return nil, "invalid_rule_" .. tostring(index)
            end
        end
        seen[rule.ruleId] = true
    end
    return true, nil
end

local function hasPrefix(value, prefixes)
    if type(value) ~= "string" then return false end
    for _, prefix in ipairs(prefixes or {}) do
        if value:sub(1, #prefix) == prefix then return true end
    end
    return false
end

function ChronicleRules.Matches(rule, article)
    if type(rule) ~= "table" or type(article) ~= "table" then return false end
    if not rule.publisherIds[article.publisherId] or not rule.articleStates[article.state] then
        return false
    end
    if not hasPrefix(article.eventType, rule.eventTypePrefixes) then return false end
    if rule.requiresLocation then
        local location = article.location
        if type(location) ~= "table" or not finite(location.x) or not finite(location.y) then
            return false
        end
    end
    return true
end

function ChronicleRules.RegionKey(rule, article)
    local location = article and article.location
    if type(location) ~= "table" then return rule.cooldownFamily .. ":galaxy" end
    return rule.cooldownFamily .. ":" .. tostring(math.floor(location.x / 25))
        .. ":" .. tostring(math.floor(location.y / 25))
end

function ChronicleRules.Roll(rule, article)
    local identity = table.concat({article.articleId, tostring(article.revision), rule.ruleId}, "|")
    local hash, hashError = NewsSchema.StableHash(identity)
    if not hash then return nil, hashError end
    local value = tonumber(hash, 16) or 0
    return (value % 1000000) / 1000000, nil
end

function ChronicleRules.Evaluate(rule, article, cooldowns, currentTime)
    if not ChronicleRules.Matches(rule, article) then
        return {matched = false, selected = false, reason = "not_matched"}, nil
    end
    local cooldownKey = ChronicleRules.RegionKey(rule, article)
    local cooldownUntil = tonumber((cooldowns or {})[cooldownKey]) or 0
    if cooldownUntil > currentTime then
        return {matched = true, selected = false, reason = "cooldown",
            cooldownKey = cooldownKey, cooldownUntil = cooldownUntil}, nil
    end
    local roll, rollError = ChronicleRules.Roll(rule, article)
    if roll == nil then return nil, rollError end
    return {
        matched = true,
        selected = roll < rule.probability,
        reason = roll < rule.probability and "selected" or "probability",
        roll = roll,
        probability = rule.probability,
        cooldownKey = cooldownKey,
        cooldownUntil = currentTime + rule.cooldownSeconds,
        outputType = rule.outputType,
        eventType = rule.eventType,
        expirySeconds = rule.expirySeconds,
    }, nil
end

return ChronicleRules
