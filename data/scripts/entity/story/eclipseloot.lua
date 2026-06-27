package.path = package.path .. ";data/scripts/lib/?.lua"
local UpgradeGenerator = include("upgradegenerator")

local EclipseLoot = {}

function dropLoot(playerIndex)
    if onClient() then return end
    
    local entity = Entity()
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    -- Base drop multiplier
    local scale = entity:getValue("cc_eclipse_loot_scale") or 1.0

    -- Drop Credits
    local faction = Faction(playerIndex)
    if faction then
        faction:receive("Looted %1% Credits from Eclipse cache.", math.floor(150000 * scale))
    end
    
    -- Drop Upgrades
    local generator = UpgradeGenerator()
    local numUpgrades = math.max(1, math.floor(scale / 1.25))
    
    for i = 1, numUpgrades do
        -- Force higher rarities based on scale
        local rType = RarityType.Rare
        if scale >= 3.0 then rType = RarityType.Exceptional end
        if scale >= 4.5 then rType = RarityType.Exotic end
        
        local upgrade = generator:generateSectorSystem(x, y, 0, Rarity(rType))
        sector:dropUpgrade(entity.translationf, nil, nil, upgrade)
    end
    
    -- Optional visual effect
    sector:createExplosion(entity.translationf, 2, false)
end
