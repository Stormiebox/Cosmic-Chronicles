package.path = package.path .. ";data/scripts/lib/?.lua"

local Dialogue = include("cosmicvaultdialogue")
local Catalog = include("cc_dialogue_catalog")

-- namespace CosmicChronicles
CosmicChronicles = {}
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"

-- Compatibility shim for galaxies that persisted the pre-v4 server script. The coordinator
-- owns all current registration and scheduling; this script performs no economy or event work.
function CosmicChronicles.initialize()
    if not onServer() then return end
    Galaxy():addScriptOnce(COORDINATOR)
    CosmicChronicles.registerLore()
end

function CosmicChronicles.registerLore()
    if not onServer() then return nil, "server_only" end
    -- Guarded no-op if the coordinator already populated the catalog; needed here too since
    -- this legacy shim can run its own registerLore() before the coordinator's initialize().
    Catalog.ensurePopulated()
    local _, publisherError = Dialogue.RegisterPublisher(Catalog.publisher)
    if publisherError then return nil, publisherError end
    return Dialogue.RegisterEntries(Catalog.publisher.publisherId, Catalog.entries)
end

function CosmicChronicles.registerStoryDialogues()
    return CosmicChronicles.registerLore()
end

return CosmicChronicles
