package.path = package.path .. ";data/scripts/lib/?.lua"
include ("callable")

-- [[ Cosmic Chronicles: Vault API Injection ]] --
local cv_success, CosmicVaultDialogue = true, require("cosmicvaultdialogue")
local cvm_success, CosmicVaultMission = true, require("cosmicvaultmission")


function initialize()
    if onClient() then
        Player():registerCallback("onStartDialog", "onStartDialog")
    end

    local entity = Entity()
    entity:setValue("valuable_object", RarityType.Uncommon)

    if onServer() then
        entity.dockable = false
    end
end

function onStartDialog(index)
    if Entity().id == index then
        invokeServerFunction("startExodus")
    end
end

function startExodus()
    Player(callingPlayer):addScriptOnce("story/exodus.lua", true)

    local x, y = Sector():getCoordinates()
    Player(callingPlayer):invokeFunction("story/exodus.lua", "beaconFound", x, y)
end
callable(nil, "startExodus")
