package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")

-- namespace CosmicChroniclesRumormonger
CosmicChroniclesRumormonger = {}

-- Helper function to fetch War Heat safely
local function getFactionWarHeat(faction)
    local realWarHeat = 0
    local success, CosmicWarBridge = pcall(require, "cosmicwarbridge")

    if success and CosmicWarBridge and CosmicWarBridge.getWarHeat then
        local rawHeat = CosmicWarBridge.getWarHeat(faction.index) or 0
        realWarHeat = math.floor(rawHeat * 100)
    elseif faction:getValue("cw_enabled") then
        local rawHeat = faction:getValue("cw_war_heat") or 0
        realWarHeat = math.floor(rawHeat * 100)
    end
    return realWarHeat
end

-- Identify the type of station by checking its active vanilla scripts
local function getStationType(entity)
    if not entity then return "generic" end
    if entity:hasScript("shipyard.lua") then return "shipyard" end
    if entity:hasScript("repairdock.lua") then return "repairdock" end
    if entity:hasScript("equipmentdock.lua") then return "equipmentdock" end
    if entity:hasScript("militaryoutpost.lua") then return "militaryoutpost" end
    if entity:hasScript("smugglersmarket.lua") then return "smugglersmarket" end
    if entity:hasScript("casino.lua") then return "casino" end
    if entity:hasScript("scrapyard.lua") then return "scrapyard" end
    if entity:hasScript("researchstation.lua") then return "researchstation" end
    if entity:hasScript("turretfactory.lua") then return "turretfactory" end
    if entity:hasScript("tradingpost.lua") then return "tradingpost" end
    if entity:hasScript("resourcedepot.lua") then return "resourcedepot" end
    if entity:hasScript("fighterfactory.lua") then return "fighterfactory" end
    return "generic"
end

-- Set a low update frequency so we don't spam the server or the chat (ticks every 60 seconds)
function CosmicChroniclesRumormonger.getUpdateInterval()
    return 60
end

-- Background loop to randomly broadcast ambient chatter overhead
function CosmicChroniclesRumormonger.updateServer(timeStep)
    -- Only talk ~30% of the time per minute to make it feel natural and not repetitive
    if random():getInt(1, 100) > 30 then return end

    local sector = Sector()
    local players = {sector:getPlayers()}

    -- Save performance: don't calculate lore if no one is in the sector
    if #players == 0 then return end

    local station = Entity()
    local faction = Faction(station.factionIndex)
    if not faction then return end

    -- Pick a random player in the sector to evaluate conditions against (e.g., good rep vs bad rep)
    local player = players[random():getInt(1, #players)]

    local x, y = sector:getCoordinates()
    local distance = math.sqrt(x * x + y * y)

    local context = {
        reputation = player:getRelations(faction.index),
        factionTrait = faction:getTrait("aggressive") and "aggressive" or "peaceful",
        factionWealth = faction:getTrait("wealthy") and "wealthy" or (faction:getTrait("poor") and "poor" or "average"),
        distanceToCenter = distance,
        warHeat = getFactionWarHeat(faction),
        stationType = getStationType(station)
    }

    local ambientLine = CosmicVaultDialogue.getValidLine("ambient", context)

    if ambientLine then
        -- Broadcast as Chatter. In Avorion, this automatically appears as overhead floating text above the sender!
        sector:broadcastChatMessage(station, ChatMessageType.Chatter, ambientLine)
    end
end

-- Determines if the "Ask for rumors" option shows up when interacting with the station
function CosmicChroniclesRumormonger.interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local craft = player.craft
    -- Don't show the dialogue if the player is somehow trying to talk to their own ship
    if craft and craft.index == Entity().index then return false end
    return true
end

-- Initializes the client-side interaction menu
function CosmicChroniclesRumormonger.initUI()
    ScriptUI():registerInteraction("Any rumors?", "onAskRumors")
end

-- Triggered on the Client when the player clicks the menu option
function CosmicChroniclesRumormonger.onAskRumors()
    -- Ping the server to find an appropriate rumor based on secret server-side states
    invokeServerFunction("getRumorFromServer")
end

-- Triggered on the Server. Calculates context and fetches the text.
function CosmicChroniclesRumormonger.getRumorFromServer()
    if not onServer() then return end

    local player = Player(callingPlayer)
    local station = Entity()
    local faction = Faction(station.factionIndex)

    if not faction then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local distance = math.sqrt(x * x + y * y)

    local context = {
        reputation = player:getRelations(faction.index),
        factionTrait = faction:getTrait("aggressive") and "aggressive" or "peaceful",
        factionWealth = faction:getTrait("wealthy") and "wealthy" or (faction:getTrait("poor") and "poor" or "average"),
        distanceToCenter = distance,
        warHeat = getFactionWarHeat(faction),
        stationType = getStationType(station)
    }

    local rumor = CosmicVaultDialogue.getValidLine("rumor", context)

    if not rumor then
        rumor = "I don't have any gossip right now, friend. The sector has been quiet."
    end

    invokeClientFunction(player, "showRumorDialog", rumor)
end
callable(CosmicChroniclesRumormonger, "getRumorFromServer")

-- Triggered on the Client. Receives the string from the server and renders the text box.
function CosmicChroniclesRumormonger.showRumorDialog(text)
    if not onClient() then return end

    local dialog = { text = text, answers = { {answer = "Interesting. Thanks."} } }

    -- Render the Avorion dialogue UI
    ScriptUI():showDialog(dialog)
end