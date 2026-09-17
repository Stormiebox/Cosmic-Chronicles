package.path = package.path .. ";data/scripts/lib/?.lua"
local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
local EventContract = include("cc_event_contract")
include("stringutility")

function initialize(eventId, seed)
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end

    local sector = Sector()
    if type(eventId) ~= "string" then return end
    EventContract.Begin(eventId, "graveyard", 1)
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then EventContract.Fail(eventId, "faction_unavailable") return end

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
    if not valid(stash) then EventContract.Fail(eventId, "black_box_creation_failed") return end
    if type(eventId) == "string" then
        EventContract.Tag(stash, eventId, "graveyard")
    end
    stash.title = "Flight Recorder (Black Box)"%_T
    stash:removeScript("stash.lua")
    stash:addScriptOnce("entity/cc_blackbox.lua")
    EventContract.Complete(eventId, 1)

    -- Add atmospheric warning
    Sector():broadcastChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Warning: Massive debris field detected. Sensor profiles match recent military casualties."%_T)

end
