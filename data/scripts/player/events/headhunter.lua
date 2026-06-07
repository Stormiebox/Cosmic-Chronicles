package.path = package.path .. ";data/scripts/lib/?.lua"

local cv_success = pcall(include, "cosmicvaultnews")

local CC_Original_createEnemies = HeadHunter.createEnemies
function HeadHunter.createEnemies(faction, useHeadhunters)
    if CC_Original_createEnemies then CC_Original_createEnemies(faction, useHeadhunters) end
    
    if onServer() and cv_success and CosmicVaultNews then
        local x, y = Sector():getCoordinates()
        CosmicVaultNews.publishArticle({
            title = "Galactic Bounty Issued!",
            content = "A massive bounty has been placed on a rogue Independent Captain due to extreme hostility against local factions. Hunter squadrons have been officially deployed to sector [" .. x .. ":" .. y .. "] to collect the bounty.",
            category = "Bounty Hunters"
        })
    end
end
