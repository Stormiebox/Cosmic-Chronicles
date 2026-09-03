package.path = package.path .. ";data/scripts/lib/?.lua"
local UpgradeGenerator = include("upgradegenerator")

function dropLoot(playerIndex)
    if onClient() then return end
    
    local entity = Entity()
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    -- Base drop multiplier
    local scale = entity:getValue("cc_eclipse_loot_scale") or 1.0

    -- Alliance Fix: Check if the player is in an Alliance craft
    local faction = Faction(playerIndex)
    local player = Player(playerIndex)
    if player and player.craft then
        faction = Faction(player.craft.factionIndex)
    end

    -- Drop Credits. %_T lets the "%1%" placeholder resolve to the money argument; faction is
    -- always a player or their alliance here, so a client always exists to translate for.
    if faction then
        faction:receive("Looted %1% Credits from Eclipse cache."%_T, math.floor(250000 * scale))
    end
    
    -- Drop Upgrades
    local generator = UpgradeGenerator()
    local numUpgrades = math.max(1, math.floor(scale / 1.25))
    
    for i = 1, numUpgrades do
        -- Force higher rarities based on scale
        local rType = RarityType.Rare
        if scale >= 3.0 then rType = RarityType.Exceptional end
        if scale >= 4.5 then rType = RarityType.Exotic end
        
        local upgrade = generator:generateSectorSystem(x, y, Rarity(rType))
        sector:dropUpgrade(entity.translationf, faction, nil, upgrade)
    end
end
