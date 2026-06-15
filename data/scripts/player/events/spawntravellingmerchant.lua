package.path = package.path .. ";data/scripts/lib/?.lua"

local cv_success = true; include("cosmicvaultnews")

local CC_Original_initialize = initialize
function initialize(...)
    if CC_Original_initialize then CC_Original_initialize(...) end
    
    if onServer() and cv_success and CosmicVaultNews then
        local x, y = Sector():getCoordinates()
        CosmicVaultNews.publishArticle({
            title = "Exotic Wares Available!",
            content = "The Independent Traders Guild reports that a renowned traveling merchant has temporarily set up shop in sector [" .. x .. ":" .. y .. "]. Captains looking for rare weaponry or equipment should act fast before they jump away!",
            category = "Trading"
        })
    end
end
