package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")

-- namespace CosmicChroniclesRumormonger
CosmicChroniclesRumormonger = {}

local cw_success = pcall(include, "cosmicwarbridge")

-- Helper function to fetch War Heat safely
local function getFactionWarHeat(faction)
    local realWarHeat = 0

    if cw_success and CosmicWarBridge and CosmicWarBridge.getFactionWarHeat then
        local rawHeat = CosmicWarBridge.getFactionWarHeat(faction.index) or 0
        realWarHeat = math.floor(rawHeat * 100)
    elseif faction:getValue("cw_enabled") then
        local rawHeat = faction:getValue("cw_war_heat") or 0
        realWarHeat = math.floor(rawHeat * 100)
    end
    return realWarHeat
end

local function getCachedStationType(entity)
    return entity:getValue("cc_station_type") or "generic"
end

-- Lowered update frequency so players see custom Cosmic chatter more often (ticks every 35 seconds)
-- TODO: Continue testing if frequency needs to be increased or lowered
function CosmicChroniclesRumormonger.getUpdateInterval()
    return 35
end

-- Background loop to randomly broadcast ambient chatter overhead
function CosmicChroniclesRumormonger.updateServer(timeStep)
    -- Increased to 50% so custom Cosmic Chronicles lore surfaces more often to compete with vanilla chatter
    -- TODO: Continue testing to ensure it isn't overshadowing vanilla dialogue lines
    if random():getInt(1, 100) > 50 then return end

    local sector = Sector()
    local currentTime = Server().unpausedRuntime
    local lastChatter = sector:getValue("cc_last_chatter") or 0

    -- GLOBAL SECTOR COOLDOWN: Reduced from 45s to 30s to increase frequency of background world-building
    -- TODO: Continue testing to ensure it isn't spamming
    if currentTime - lastChatter < 30 then return end

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
        stationType = getCachedStationType(station)
    }

    local ambientLine = CosmicVaultDialogue.getValidLine("ambient", context)

    if ambientLine then
        -- Lock the token bucket so no other station can speak for the next 45 seconds
        sector:setValue("cc_last_chatter", currentTime)

        -- Broadcast as Chatter. In Avorion, this automatically appears as overhead floating text above the sender!
        sector:broadcastChatMessage(station, ChatMessageType.Chatter, ambientLine)
    end
end

-- Determines if the "Ask for rumors" option shows up when interacting with the station
-- TODO: Ensure this guard actually functions often and in high populated servers and server runtime
function CosmicChroniclesRumormonger.interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local craft = player.craft
    -- Don't show the dialogue if the player is somehow trying to talk to their own ship
    if craft and craft.index == Entity().index then return false end

    -- Base Threshold: Prevent casually asking for rumors from fiercely hostile stations (-30k rep)
    local threshold = -30000

    -- Cosmic Overhaul Synergy: Smugglers and Explorers know how to quietly buy drinks and extract
    -- information even in hostile ports, extending their rumor access significantly.
    if craft then
        local captain = craft:getCaptain()
        if captain then
            local CaptainClass = include("captainclass")
            if captain:hasClass(CaptainClass.Smuggler) or captain:hasClass(CaptainClass.Explorer) then
                threshold = -60000
            end
        end
    end

    local faction = Faction(Entity().factionIndex)
    if faction and player:getRelations(faction.index) <= threshold then return false end

    return true
end

-- Initializes the client-side interaction menu
function CosmicChroniclesRumormonger.initUI()
    ScriptUI():registerInteraction("Any rumors?"%_t, "onAskRumors")
end

-- Triggered on the Client when the player clicks the menu option
function CosmicChroniclesRumormonger.onAskRumors()
    -- Show a waiting dialog to prevent the interaction window from closing!
    local dialog = { text = "Let me think for a moment..."%_t, answers = {} }
    ScriptUI():showDialog(dialog)

    -- Ping the server to find an appropriate rumor based on secret server-side states
    invokeServerFunction("getRumorFromServer")
end

function CosmicChroniclesRumormonger.getRumorFromServer()
    if not onServer() then return end

    local player = Player(callingPlayer)
    local station = Entity()
    local faction = Faction(station.factionIndex)

    local rumor = nil

    if faction then
        local sector = Sector()
        local x, y = sector:getCoordinates()
        local distance = math.sqrt(x * x + y * y)

        local context = {
            reputation = player:getRelations(faction.index),
            factionTrait = faction:getTrait("aggressive") and "aggressive" or "peaceful",
            factionWealth = faction:getTrait("wealthy") and "wealthy" or (faction:getTrait("poor") and "poor" or "average"),
            distanceToCenter = distance,
            warHeat = getFactionWarHeat(faction),
            stationType = getCachedStationType(station)
        }

        rumor = CosmicVaultDialogue.getValidLine("rumor", context)
    end

    if not rumor then
        rumor = "I don't have any gossip right now, friend. The sector has been quiet."
    end

    invokeClientFunction(player, "showRumorDialog", tostring(rumor))
end
callable(CosmicChroniclesRumormonger, "getRumorFromServer")

-- Triggered on the Client. Receives the string from the server and renders the text box.
function CosmicChroniclesRumormonger.showRumorDialog(rumor)
    if not onClient() then return end

    local dialog = { text = rumor%_t, answers = { {answer = "Interesting. Thanks."%_t} } }

    -- Render the Avorion dialogue UI
    ScriptUI():showDialog(dialog)
end
