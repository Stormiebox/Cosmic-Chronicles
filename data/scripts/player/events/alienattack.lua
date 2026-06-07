package.path = package.path .. ";data/scripts/lib/?.lua"

local cv_success = pcall(include, "cosmicvaultnews")

local CC_Original_createEnemies = createEnemies
function createEnemies(volumes, attackType, message)
    if CC_Original_createEnemies then CC_Original_createEnemies(volumes, attackType, message) end
    
    if onServer() and cv_success and CosmicVaultNews then
        local x, y = Sector():getCoordinates()
        CosmicVaultNews.publishArticle({
            title = "Dimensional Ruptures Detected!",
            content = "Warning! A catastrophic surge of Xsotan entities has flooded sector [" .. x .. ":" .. y .. "]. Faction authorities are advising all civilian traffic to evacuate immediately.",
            category = "Galactic Threat"
        })
    end
end
