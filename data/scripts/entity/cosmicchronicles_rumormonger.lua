package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("stringutility")

local Weather = include("cosmicvaultweather")
local Rift = include("cosmicvaultrift")
local News = include("cosmicvaultnews")
local warAvailable, War = pcall(include, "cosmicwarbridge")

-- namespace CosmicChroniclesRumormonger
CosmicChroniclesRumormonger = {}

local PLAYER_CONTROLLER = "data/scripts/player/background/cc_player_controller.lua"
local ASCENDANCY_COORDINATOR = "data/scripts/galaxy/ca_state_coordinator.lua"

local function stationType(entity)
    local cached = entity:getValue("cc_station_type")
    if type(cached) == "string" then return cached end
    local types = {
        {"data/scripts/entity/merchants/shipyard.lua", "shipyard"},
        {"data/scripts/entity/merchants/repairdock.lua", "repairdock"},
        {"data/scripts/entity/merchants/equipmentdock.lua", "equipmentdock"},
        {"data/scripts/entity/merchants/militaryoutpost.lua", "militaryoutpost"},
        {"data/scripts/entity/merchants/smugglersmarket.lua", "smugglersmarket"},
        {"data/scripts/entity/merchants/casino.lua", "casino"},
        {"data/scripts/entity/merchants/scrapyard.lua", "scrapyard"},
        {"data/scripts/entity/merchants/researchstation.lua", "researchstation"},
        {"data/scripts/entity/merchants/turretfactory.lua", "turretfactory"},
        {"data/scripts/entity/merchants/tradingpost.lua", "tradingpost"},
        {"data/scripts/entity/merchants/resourcedepot.lua", "resourcedepot"},
        {"data/scripts/entity/merchants/fighterfactory.lua", "fighterfactory"},
    }
    cached = "generic"
    for _, definition in ipairs(types) do
        if entity:hasScript(definition[1]) then cached = definition[2] break end
    end
    entity:setValue("cc_station_type", cached)
    return cached
end

local function playerInSector(playerIndex)
    for _, candidate in pairs({Sector():getPlayers()}) do
        if candidate and candidate.index == playerIndex then return candidate end
    end
end

local function warHeat(faction)
    if warAvailable and War and War.getFactionWarHeat then
        return math.floor((tonumber(War.getFactionWarHeat(faction.index)) or 0) * 100)
    end
    return 0
end

local function eclipseFacts(playerIndex)
    local facts = {}
    local status, snapshot = Galaxy():invokeFunction(ASCENDANCY_COORDINATOR,
        "getCanonicalSnapshot", playerIndex)
    if status ~= 0 or type(snapshot) ~= "table" then return facts end
    local state = snapshot.state
    local eclipse = state and state.eclipse
    if type(eclipse) == "table" then
        if eclipse.unleashed then facts.unleashed = true end
        if eclipse.fullyAwake then facts.fully_awake = true end
        if eclipse.fallenEmpire then facts.fallen_empire = true end
    end
    return facts
end

local function nearbyFacts(playerIndex, x, y)
    local publishers, topics, severities = {}, {}, {}
    local page = News.Query({pageSize = 25, audiencePlayerIndex = playerIndex,
        location = {x = x, y = y, radius = 20}})
    for _, article in ipairs(page and page.items or {}) do
        publishers[article.publisherId] = true
        topics[article.topic] = true
        severities[article.severity] = true
    end
    return publishers, topics, severities
end

local function buildContext(targetPlayer)
    local station = Entity()
    local faction = Faction(station.factionIndex)
    if not faction then return nil, "missing_faction" end
    local x, y = Sector():getCoordinates()
    local weatherTypes = {}
    local riftActive = false
    local weather = Weather.ListWeatherAt(x, y)
    for _, condition in ipairs(weather or {}) do
        if type(condition.weatherType) == "string" then
            weatherTypes[condition.weatherType] = true
            if condition.weatherType == "RiftInstability" then riftActive = true end
        end
    end
    local riftSnapshot = Rift.GetEscalationSnapshot()
    if riftSnapshot and tonumber(riftSnapshot.escalation) and riftSnapshot.escalation > 0
            and weatherTypes.RiftInstability then riftActive = true end
    local publisherIds, topics, severities = nearbyFacts(targetPlayer.index, x, y)
    local trait = faction:getTrait("aggressive") > 0.5 and "aggressive" or "peaceful"
    local wealth = faction.money > 10000000 and "wealthy"
        or faction.money < 1000000 and "poor" or "average"
    local captainClass
    local craft = targetPlayer.craft
    local captain = craft and craft:getCaptain()
    if captain then captainClass = tostring(captain.primaryClass) end
    return {
        reputation = targetPlayer:getRelations(faction.index),
        factionTrait = trait,
        factionWealth = wealth,
        distanceToCenter = math.sqrt(x * x + y * y),
        warHeat = warHeat(faction),
        stationType = stationType(station),
        publisherIds = publisherIds,
        topics = topics,
        severities = severities,
        weatherTypes = weatherTypes,
        riftActive = riftActive,
        eclipseStates = eclipseFacts(targetPlayer.index),
        captainClass = captainClass,
    }, nil
end

local function selectLine(targetPlayer, category)
    local context, contextError = buildContext(targetPlayer)
    if not context then return nil, contextError end
    local identity = tostring(Entity().index)
    local identitySeed = 0
    for index = 1, #identity do
        identitySeed = (identitySeed * 33 + identity:byte(index)) % 2147483647
    end
    local seed = math.floor(Server().unpausedRuntime) + targetPlayer.index + identitySeed
    local status, selected, selectError = targetPlayer:invokeFunction(PLAYER_CONTROLLER,
        "selectDialogue", targetPlayer.index, category, context, seed)
    if status ~= 0 then return nil, "controller_unavailable" end
    if not selected then return nil, selectError end
    return selected.text, nil, selected.lineId
end

function CosmicChroniclesRumormonger.initialize()
    if onServer() and Entity().isStation then stationType(Entity()) end
end

function CosmicChroniclesRumormonger.interactionPossible(playerIndex, option)
    local targetPlayer = Player(playerIndex)
    local station = Entity()
    if not targetPlayer or not targetPlayer.craft then return false end
    if targetPlayer.craft.index == station.index
            or targetPlayer.craft:getNearestDistance(station) > 1000 then return false end
    local faction = Faction(station.factionIndex)
    if not faction then return false end
    return targetPlayer:getRelations(faction.index) > -30000
end

function CosmicChroniclesRumormonger.initUI()
    ScriptUI():registerInteraction("Any rumors?"%_t, "onAskRumors")
end

function CosmicChroniclesRumormonger.onAskRumors()
    ScriptUI():showDialog({text = "Let me think for a moment..."%_t, answers = {}})
    invokeServerFunction("getRumorFromServer")
end

function CosmicChroniclesRumormonger.getAmbientLine(playerIndex)
    if not onServer() then return nil, "server_only" end
    local targetPlayer = playerInSector(playerIndex)
    if not targetPlayer then return nil, "player_not_present" end
    return selectLine(targetPlayer, "ambient")
end

function CosmicChroniclesRumormonger.getRumorFromServer()
    if not onServer() then return end
    local targetPlayer = playerInSector(callingPlayer)
    local station = Entity()
    if not targetPlayer or not targetPlayer.craft
            or targetPlayer.craft:getNearestDistance(station) > 1000 then
        if targetPlayer then invokeClientFunction(targetPlayer, "tooFar") end
        return
    end
    local rumor = selectLine(targetPlayer, "rumor")
        or "I don't have any gossip right now, friend. The sector has been quiet."
    invokeClientFunction(targetPlayer, "showRumorDialog", tostring(rumor))
end

function CosmicChroniclesRumormonger.showRumorDialog(rumor)
    if not onClient() then return end
    ScriptUI():showDialog({text = tostring(rumor),
        answers = {{answer = "Interesting. Thanks."%_t}}})
end

function CosmicChroniclesRumormonger.tooFar()
    if not onClient() then return end
    ScriptUI():interactShowDialog({
        text = "You're too far away. Come closer to converse."%_t}, true)
end

callable(CosmicChroniclesRumormonger, "getRumorFromServer")

return CosmicChroniclesRumormonger
