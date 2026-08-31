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
    -- Guarded by "not _restoring": initialize() re-fires with _restoring=true on every
    -- sector/database load, and without this guard the custom lines would be appended
    -- again on every reload, growing data.lines without bound.
    if onServer() and not _restoring then
        local entity = Entity()
        local faction = Faction(entity.factionIndex)
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
                reputation = 0,
                factionTrait = factionTrait,
                factionWealth = factionWealth,
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



