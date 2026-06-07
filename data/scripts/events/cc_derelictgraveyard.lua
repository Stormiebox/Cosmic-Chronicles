package.path = package.path .. ";data/scripts/lib/?.lua"
local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
include("stringutility")

function initialize()
    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then terminate() return end

    -- Spawn ships and immediately destroy them to let Avorion's physics engine handle the wreckage scatter
    local count = random():getInt(3, 5)
    for i = 1, count do
        local ship = ShipGenerator.createMilitaryShip(faction, MatrixLookUpPosition(-vec3(1,0,0), vec3(0,1,0), vec3(random():getInt(-500, 500), random():getInt(-500, 500), random():getInt(-500, 500))))
        ship.durability = 1
        ship:destroy(ship.index) -- Instantly destroy the ship to generate standard wreckage and explosion VFX
    end

    -- Spawn a Black Box stash for players to recover the final log
    local generator = SectorGenerator(sector:getCoordinates())
    local position = MatrixLookUpPosition(-vec3(1,0,0), vec3(0,1,0), vec3(random():getInt(-50, 50), random():getInt(-50, 50), random():getInt(-50, 50)))
    local stash = generator:createStash(position)
    stash.title = "Flight Recorder (Black Box)"%_T
    stash:removeScript("stash.lua")
    stash:addScriptOnce("entity/cc_blackbox.lua")

    -- Add atmospheric warning
    Sector():broadcastChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Warning: Massive debris field detected. Sensor profiles match recent military casualties."%_T)

    local cv_success = pcall(include, "cosmicvaultnews")
    if cv_success and CosmicVaultNews then
        CosmicVaultNews.publishArticle({
            title = "Derelict Graveyard Discovered",
            content = "A massive graveyard of derelict ships has been located by an independent captain in sector [" .. x .. ":" .. y .. "]. Scavengers are warned that the area may still contain live munitions or hostile drones.",
            category = "Exploration"
        })
    end

    terminate()
end