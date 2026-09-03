package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local Placer = include("placer")
local PlanGenerator = include("plangenerator")
local Balancer = include("galaxy")
local ShipUtility = include("shiputility")
-- Needed for %_t/%_T below; no vanilla file at this path to inherit it from.
include("stringutility")

local BountyAmbush = {}

function BountyAmbush.initialize()
    if onServer() then
        BountyAmbush.spawn()
    end
end

function BountyAmbush.spawn()
    local sector = Sector()

    -- Exploit Fix: A boss is already active in this sector (e.g. sector reload before it was killed) - don't stack another.
    if sector:getValue("cc_bounty_boss_spawned") then return end
    sector:setValue("cc_bounty_boss_spawned", true)

    local x, y = sector:getCoordinates()

    -- getPirateFaction takes a pirate difficulty level, computed the vanilla-standard way.
    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    
    local volume = Balancer.getSectorShipVolume(x, y) * 5 -- Boss volume
    local plan = PlanGenerator.makeShipPlan(faction, volume)
    
    local boss = sector:createShip(faction, "", plan, SectorGenerator(x,y):getPositionInSector())
    boss.title = "Dread Pirate Lord"
    boss.name = "Bounty Target"
    boss.crew = boss.idealCrew
    boss:addScript("icon.lua", "data/textures/icons/pixel/double_skull_big.png")
    
    ShipUtility.addArmedTurretsToCraft(boss, 3)
    boss.damageMultiplier = (boss.damageMultiplier or 1) * 2
    boss:setValue("is_pirate", true)
    
    -- Drop massive loot and credits on destruction
    boss:registerCallback("onDestroyed", "onBossDestroyed")
    
    -- Spawn some minions
    local numMinions = 4
    for i = 1, numMinions do
        local minion = PirateGenerator.createPirate()
        Placer.resolveIntersections({minion})
    end
    
    Sector():broadcastChatMessage(boss.title, 0, "So, you're the one trying to collect the bounty? You've just walked into your own grave!")
end

function BountyAmbush.onBossDestroyed()
    local sector = Sector()
    local x, y = sector:getCoordinates()

    local players = {sector:getPlayers()}
    for _, player in pairs(players) do
        local reward = 2500000 -- 2.5 million credits
        -- %_T needed for the "%1%"/"%2%" placeholders below to resolve.
        player:receive("Received %1% Credits for claiming the bounty."%_T, reward)
        player:sendChatMessage("Galactic News Network", 0, "Bounty claimed successfully in sector [%1%:%2%]."%_T, x, y)
    end

    -- Exploit Fix: Detach this sector script now that the bounty is paid, so a sector reload can't spawn another boss.
    terminate()
end

function initialize(...)
    if BountyAmbush.initialize then return BountyAmbush.initialize(...) end
end

function onBossDestroyed(...)
    if BountyAmbush.onBossDestroyed then return BountyAmbush.onBossDestroyed(...) end
end
