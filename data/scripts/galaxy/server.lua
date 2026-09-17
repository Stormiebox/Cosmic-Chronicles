
local CosmicChronicles_old_init = initialize
local CosmicChronicles_Coordinator = "data/scripts/galaxy/cc_coordinator.lua"

function initialize(...)
    if CosmicChronicles_old_init then CosmicChronicles_old_init(...) end
    Galaxy():addScriptOnce(CosmicChronicles_Coordinator)
    if not Galaxy():hasScript(CosmicChronicles_Coordinator) then
        print("[Cosmic Chronicles] Coordinator failed to attach.")
    end
end
