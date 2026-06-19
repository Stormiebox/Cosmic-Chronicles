-- namespace EntityRadioChatter
local CosmicVaultDialogue = include("cosmicvaultdialogue")

-- Cache the original vanilla function
local cc_vanilla_initialize = EntityRadioChatter.initialize

function EntityRadioChatter.initialize(lines, minFrequency, maxFrequency, timeToFirst, speechBubbleOnly)
    -- Safely call the vanilla initialize first so the script sets up its internal data
    if cc_vanilla_initialize then
        cc_vanilla_initialize(lines, minFrequency, maxFrequency, timeToFirst, speechBubbleOnly)
    end

    -- Now, silently inject our own custom ambient lines into the entity's data pool!
    if onServer() then
        local entity = Entity()
        local faction = Faction(entity.factionIndex)
        if faction then
            local sector = Sector()
            local x, y = sector:getCoordinates()
            local distance = math.sqrt(x * x + y * y)

            local context = {
                reputation = 0,
                factionTrait = faction:getTrait("aggressive") and "aggressive" or "peaceful",
                factionWealth = faction:getTrait("wealthy") and "wealthy" or (faction:getTrait("poor") and "poor" or "average"),
                distanceToCenter = distance,
                warHeat = 0,
                stationType = "ship"
            }

            -- We can pull 3 random ambient lines and append them to the entity's chatter array
            for i = 1, 3 do
                local customLine = CosmicVaultDialogue.getValidLine("ambient", context)
                if customLine then
                    -- EntityRadioChatter stores its lines in 'data.lines' internally
                    local data = EntityRadioChatter.secure()
                    table.insert(data.lines, customLine)
                end
            end
        end
    end
end


function initialize(...)
    if EntityRadioChatter.initialize then return EntityRadioChatter.initialize(...) end
end
