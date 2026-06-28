package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
local UpgradeGenerator = include("upgradegenerator")
include("callable")

function initialize()
    if onServer() then
        Entity().title = "Derelict Black Box"
    end
end

function interactionPossible(playerIndex, option)
    return true
end

function initUI()
    ScriptUI():registerInteraction("Extract Audio Log", "onInteract")
end

function onInteract()
    ScriptUI():showDialog(Dialog())
end

function Dialog()
    local d0 = {}
    d0.text = "[STATIC] ...this is Grand Admiral Vance of the First Vanguard... [STATIC] ...we were supposed to hold the line... but they just kept warping in. They didn't even use the gates. [STATIC] ...my entire armada is gone. If anyone finds this... turn back. You cannot fight them."
    d0.answers = { {answer = "Decrypt attached coordinates and salvage.", onSelect = "triggerLoot"} }
    return d0
end

function triggerLoot()
    if onClient() then
        invokeServerFunction("triggerLootServer")
        return
    end
end

function triggerLootServer()
    local entity = Entity()
    local player = Player(callingPlayer)
    local craft = player.craft
    
    local isScavenger = false
    local isExplorer = false
    
    if craft then
        local captain = craft:getCaptain()
        if captain then
            if captain:hasClass(CaptainClass.Scavenger) then isScavenger = true end
            if captain:hasClass(CaptainClass.Explorer) then isExplorer = true end
        end
    end
    
    local sector = Sector()
    local x, y = sector:getCoordinates()
    local d = math.sqrt(x*x + y*y)
    local scale = math.max(1, (500 - d) / 100)
    
    local bonusMultiplier = 1.0
    if isScavenger or isExplorer then
        bonusMultiplier = 1.5
        player:sendChatMessage("Captain", 0, "I managed to decrypt an isolated sub-routine in this cache! We found extra salvage!")
    end
    
    -- Drop Credits
    local faction = Faction(callingPlayer)
    if faction then
        faction:receive("Extracted %1% Credits from Black Box.", math.floor(75000 * scale * bonusMultiplier))
    end
    
    -- Drop Upgrades
    local generator = UpgradeGenerator()
    local numUpgrades = math.floor(2 * scale)
    
    for i = 1, numUpgrades do
        local rType = RarityType.Rare
        if scale >= 3.0 then rType = RarityType.Exceptional end
        if (isScavenger or isExplorer) and random():test(0.5) then
            rType = RarityType.Exotic
        end
        
        local upgrade = generator:generateSectorSystem(x, y, 0, Rarity(rType))
        sector:dropUpgrade(entity.translationf, nil, nil, upgrade)
    end
    
    sector:createExplosion(entity.translationf, 1.5, false)
    sector:deleteEntity(entity)
end

callable(nil, "triggerLootServer")
