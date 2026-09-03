package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
include("stringutility")

local DiplomatEscort = {}

function DiplomatEscort.initialize()
    if onServer() then DiplomatEscort.spawn() end
end

function DiplomatEscort.spawn()
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)
    
    if not faction or faction.name == "The Xsotan" or faction.name == "The Xsotan"%_t or faction.isPlayer or faction.isAlliance then
        terminate()
        return
    end

    local diplomat = ShipGenerator.createFreighterShip(faction, SectorGenerator(x,y):getPositionInSector())
    diplomat.title = "Stranded Diplomat"%_T
    diplomat:addScriptOnce("data/scripts/entity/story/diplomatdialog.lua")

    -- Strip AI and weapons so the "stranded, escort destroyed" ship is actually stranded,
    -- matching the sibling cc_ghostship.lua convention for a disabled derelict freighter.
    diplomat:removeScript("data/scripts/entity/ai/patrol.lua")
    diplomat:removeScript("data/scripts/entity/ai/freighter.lua")

    -- Root cause of the reported "special dialog didn't show, towing cost 15000 rep" bug:
    -- ShipGenerator.createFreighterShip (vanilla lib/shipgenerator.lua) always attaches
    -- civilship.lua on top of the AI scripts above - this was never being removed. It
    -- registers its own competing interaction options ("Where is your home sector?",
    -- "Give me all your cargo!") alongside diplomatdialog.lua's "Open Comm Link", so the
    -- intended rescue option had to compete with generic vanilla civilian-ship prompts in
    -- the same menu. Worse, civilship.lua's own CivilShip.threaten() - reachable via that
    -- "Give me all your cargo!" path, or a client-triggered hostile action like towing -
    -- calls CivilShip.worsenRelations() with its default delta of exactly -15000, matching
    -- the reported reputation loss precisely. Removing it leaves only the intended dialog.
    diplomat:removeScript("data/scripts/entity/civilship.lua")

    local ai = ShipAI(diplomat.index)
    if ai then
        ai:stop()
        ai:setPassive()
    end

    local turrets = {diplomat:getTurrets()}
    for _, turret in pairs(turrets) do
        Sector():deleteEntity(turret)
    end

    diplomat.crew = Crew()

    -- Strip real faction ownership after spawn: `faction` above was only ever
    -- needed for the spawn-eligibility check (not Xsotan/player/alliance) and
    -- diplomatdialog.lua's own payout logic never references the diplomat's
    -- faction again, so this ship staying a real, tracked asset of an ally
    -- faction for its whole lifetime serves no gameplay purpose - it just
    -- means any vanilla interaction that doesn't go through the dialog (tow,
    -- forced boarding) reads to the game as stealing from that faction and
    -- applies a real reputation penalty against them. 0 is vanilla's own
    -- "no faction" sentinel (see e.g. entity/antismuggle.lua's
    -- `if ship.factionIndex == 0 then goto continue end`). The diplomat's
    -- dialogue text is flavor and doesn't depend on real faction ownership.
    diplomat.factionIndex = 0

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Emergency civilian broadcast detected: 'Our escort is destroyed. We require immediate extraction!' Dock and open a comm link to negotiate extraction - towing or attacking the ship risks your reputation with its faction."%_T)
end

function initialize(...)
    if DiplomatEscort.initialize then DiplomatEscort.initialize(...) end
    terminate()
end
