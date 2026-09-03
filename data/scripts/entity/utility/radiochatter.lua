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

            -- Real Avorion traits are aggressive/brave/greedy/honorable/mistrustful only, so
            -- wealth is judged from faction.money directly instead of a nonexistent trait.
            local factionWealth = "average"
            if faction.money > 10000000 then
                factionWealth = "wealthy"
            elseif faction.money < 1000000 then
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

            -- secure() returns the same internal 'data.lines' table reference every call,
            -- so fetch it once rather than inside the loop below.
            local data = EntityRadioChatter.secure()

            -- We can pull 3 random ambient lines and append them to the entity's chatter array
            for i = 1, 3 do
                local customLine = CosmicVaultDialogue.getValidLine("ambient", context)
                if customLine then
                    table.insert(data.lines, customLine)
                end
            end
        end
    end
end



