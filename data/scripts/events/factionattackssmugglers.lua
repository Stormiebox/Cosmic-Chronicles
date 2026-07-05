package.path = package.path .. ";data/scripts/lib/?.lua"

-- namespace FactionAttacksSmugglers
-- local cv_success = true; include("cosmicvaultnews")

local CC_Original_spawnDefenders = FactionAttacksSmugglers.spawnDefenders
function FactionAttacksSmugglers.spawnDefenders()
    if CC_Original_spawnDefenders then CC_Original_spawnDefenders() end
    
    if onServer() then
        local x, y = Sector():getCoordinates()
        local article = {
            title = "Major Sting Operation!",
            content = "Breaking news! Local military forces have cracked down on a major Black Market operation in sector [" .. x .. ":" .. y .. "]. A massive shootout has ensued as smugglers refuse to surrender to the authorities.",
            category = "Conflict"
        }
        local cv_news = include("cosmicvaultnews")
    cv_news.publishArticle(article)
    end
end
