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
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    if craft:getNearestDistance(Entity()) > 500 then return false end
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
    if not player then return end

    local craft = player.craft
    if not craft then return end

    -- Multiplayer Exploit Fix: Verify distance on the server before dropping loot!
    if craft:getNearestDistance(entity) > 500 then
        invokeClientFunction(player, "tooFar")
        return
    end

    if entity:getValue("cc_loot_triggered") then return end
    entity:setValue("cc_loot_triggered", true)

    local isScavenger = false
    local isExplorer = false

    local captain = craft:getCaptain()
    if captain then
        if captain:hasClass(CaptainClass.Scavenger) then isScavenger = true end
        if captain:hasClass(CaptainClass.Explorer) then isExplorer = true end
    end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local d = math.sqrt(x*x + y*y)
    local scale = math.max(1, (500 - d) / 100)

    local bonusMultiplier = 1.0
    if isScavenger or isExplorer then
        bonusMultiplier = 2.0
        player:sendChatMessage("Captain", 0, "I managed to decrypt an isolated sub-routine in this cache! We found extra salvage!")
    end

    -- Alliance Fix: Give credits to the faction of the craft, not just the calling player!
    local faction = Faction(craft.factionIndex)
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
        sector:dropUpgrade(entity.translationf, faction, nil, upgrade)
    end

    sector:createExplosion(entity.translationf, 1.5, false)
    sector:deleteEntity(entity)
end

callable(nil, "triggerLootServer")

function tooFar()
    local dialog = {}
    dialog.text = "You're too far away. Come closer so you can interface with the cache."%_t
    ScriptUI():interactShowDialog(dialog, true)
end
