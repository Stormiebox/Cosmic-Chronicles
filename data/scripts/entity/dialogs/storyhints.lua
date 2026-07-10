-- namespace StoryHints

local CosmicVaultDialogue = include("cosmicvaultdialogue")
include("callable")
local cw_success = true; include("cosmicwarbridge")

-- Cache the original vanilla function so we don't break it
local cc_vanilla_onAnythingInteresting = StoryHints.onAnythingInteresting

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

function StoryHints.onAnythingInteresting()
    -- Intercept the vanilla UI call on the Client VM and show a placeholder to keep the interaction window open
    local dialog = { text = "Let me think for a moment..."%_t, answers = {} }
    ScriptUI():showDialog(dialog)
    
    -- Ask the Server VM for rumors since CosmicVaultDialogue._registeredLines is populated on the Server
    invokeServerFunction("cc_getStoryHintFromServer")
end

function StoryHints.cc_getStoryHintFromServer()
    if not onServer() then return end
    
    local player = Player(callingPlayer)
    local station = Entity()
    local faction = Faction(station.factionIndex)
    
    local rumor = nil
    
    if faction then
        local sector = Sector()
        local x, y = sector:getCoordinates()
        local distance = math.sqrt(x * x + y * y)
        
        local factionTrait = "peaceful"
        if faction:getTrait("aggressive") > 0.5 then
            factionTrait = "aggressive"
        end

        local factionWealth = "average"
        if faction:getTrait("wealthy") > 0.5 then
            factionWealth = "wealthy"
        elseif faction:getTrait("poor") > 0.5 then
            factionWealth = "poor"
        end
        
        local context = {
            reputation = player:getRelations(faction.index),
            factionTrait = factionTrait,
            factionWealth = factionWealth,
            distanceToCenter = distance,
            warHeat = getFactionWarHeat(faction),
            stationType = station:getValue("cc_station_type") or "generic"
        }
        
        rumor = CosmicVaultDialogue.getValidLine("rumor", context)
        
        if rumor and random():test(0.60) then
            invokeClientFunction(player, "cc_showCustomStoryHint", tostring(rumor))
            return
        end
    end
    
    -- Fallback to vanilla
    invokeClientFunction(player, "cc_showVanillaStoryHint")
end
callable(StoryHints, "cc_getStoryHintFromServer")

function StoryHints.cc_showCustomStoryHint(rumor)
    if not onClient() then return end
    local dialog = { text = rumor%_t, answers = { {answer = "Interesting. Thanks."%_t} } }
    ScriptUI():showDialog(dialog)
end

function StoryHints.cc_showVanillaStoryHint()
    if not onClient() then return end
    if cc_vanilla_onAnythingInteresting then
        cc_vanilla_onAnythingInteresting()
    end
end
