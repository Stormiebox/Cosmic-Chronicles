package.path = package.path .. ";data/scripts/lib/?.lua"

local cvn = include("cosmicvaultnews")

local CC_SpawnBehemoth_finish = SpawnBehemoth.finish
function SpawnBehemoth.finish()
    if not onServer() then 
        if CC_SpawnBehemoth_finish then CC_SpawnBehemoth_finish() end
        return 
    end

    local sector = Sector()
    local behemoth = sector:getEntitiesByScriptValue("behemoth_boss")
    
    if behemoth then
        local x, y = sector:getCoordinates()
        local players = sector:getPlayers()
        local survived = (players ~= nil)

        local data = SpawnBehemoth.secure() or {}
        local quadName = "Unknown"
        if data.quadrant == 1 then quadName = "North"
        elseif data.quadrant == 2 then quadName = "East"
        elseif data.quadrant == 3 then quadName = "South"
        elseif data.quadrant == 4 then quadName = "West" end

        if survived then
            local article = {
                title = "Behemoth Assault Repelled!",
                content = "Incredible news! Independent captains have successfully driven the Behemoth of the " .. quadName .. " out of sector [" .. x .. ":" .. y .. "]. The sector has been saved from total annihilation.",
                category = "Galactic Threat"
            }
            if cvn then cvn.publishArticle(article) end
        else
            local article = {
                title = "Sector Obliterated by Behemoth",
                content = "Tragedy strikes. The Behemoth of the " .. quadName .. " has completely wiped out all life and infrastructure in sector [" .. x .. ":" .. y .. "]. The beast has moved on, leaving nothing but ruin in its wake.",
                category = "Galactic Threat"
            }
            if cvn then cvn.publishArticle(article) end
        end
    end

    -- Call the original vanilla function which handles deletion and destruction
    if CC_SpawnBehemoth_finish then
        CC_SpawnBehemoth_finish()
    end
end
