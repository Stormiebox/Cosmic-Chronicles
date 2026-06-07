-- namespace StoryHints
local cv_success, CosmicVaultDialogue = pcall(require, "cosmicvaultdialogue")

-- Cache the original vanilla function so we don't break it
local cc_vanilla_onAnythingInteresting = StoryHints.onAnythingInteresting

function StoryHints.onAnythingInteresting()
    -- 1. Try to get a Cosmic Chronicles rumor first
    local player = Player()
    local station = Entity()
    local faction = Faction(station.factionIndex)
    
    if cv_success and faction then
        local sector = Sector()
        local x, y = sector:getCoordinates()
        local distance = math.sqrt(x * x + y * y)
        
        local context = {
            reputation = player:getRelations(faction.index),
            factionTrait = faction:getTrait("aggressive") and "aggressive" or "peaceful",
            factionWealth = faction:getTrait("wealthy") and "wealthy" or (faction:getTrait("poor") and "poor" or "average"),
            distanceToCenter = distance,
            warHeat = 0, -- Default fallback, we can expand later
            stationType = station:getValue("cc_station_type") or "generic"
        }
        
        local rumor = CosmicVaultDialogue.getValidLine("rumor", context)
        
        -- 2. If we found a custom rumor, display it and RETURN early (suppressing the vanilla hint)
        if rumor and random():test(0.60) then -- 60% chance to override vanilla if a rumor exists
            local dialog = { text = rumor%_t, answers = { {answer = "Interesting. Thanks."%_t} } }
            ScriptUI():showDialog(dialog)
            return
        end
    end
    
    -- 3. If no custom rumor is found (or we lose the roll), fallback to the original vanilla logic
    if cc_vanilla_onAnythingInteresting then
        cc_vanilla_onAnythingInteresting()
    end
end
