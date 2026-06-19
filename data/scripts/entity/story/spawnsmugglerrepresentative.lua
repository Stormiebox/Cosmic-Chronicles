
local Smuggler = include("story/smuggler")

-- [[ Cosmic Chronicles: Vault API Injection ]] --
local CosmicVaultDialogue = include("cosmicvaultdialogue")
local CosmicVaultMission = include("cosmicvaultmission")


-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace SpawnSmugglerRepresentative
SpawnSmugglerRepresentative = {}

if onServer() then

function SpawnSmugglerRepresentative.initialize()

    if not _restoring then
        Smuggler.spawnRepresentative(Entity())
    else
        Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end
end

function SpawnSmugglerRepresentative.onRestoredFromDisk()
    Smuggler.spawnRepresentative(Entity())
end



end


function initialize(...)
    if SpawnSmugglerRepresentative.initialize then return SpawnSmugglerRepresentative.initialize(...) end
end


-- Global Event Callbacks
function onRestoredFromDisk(...)
    if SpawnSmugglerRepresentative.onRestoredFromDisk then return SpawnSmugglerRepresentative.onRestoredFromDisk(...) end
end
