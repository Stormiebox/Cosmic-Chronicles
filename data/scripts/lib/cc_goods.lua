local VaultGoods = include("cosmicvaultgoods")

local ChronicleGoods = {}

local GOODS = {
    {
        name = "Subclass Subsystem",
        plural = "Subclass Subsystems",
        description = "A heavily encrypted prototype subsystem core.",
        icon = "data/textures/icons/circuit-board.png",
        price = 125000,
        size = 2.0,
        illegal = true,
        dangerous = true,
        stolen = true,
        tags = {},
    },
}

function ChronicleGoods.RegisterAll()
    for _, definition in ipairs(GOODS) do VaultGoods.registerGood(definition) end
    return true
end

function ChronicleGoods.GetDefinitions()
    local result = {}
    for index, definition in ipairs(GOODS) do
        result[index] = {}
        for key, value in pairs(definition) do result[index][key] = value end
    end
    return result
end

return ChronicleGoods
