include("cosmicchronicles")

-- Capture the original initialize function (if any) and inject our own
local CosmicChronicles_old_initialize = initialize
function initialize(...)
    if CosmicChronicles_old_initialize then CosmicChronicles_old_initialize(...) end
    CosmicChronicles.initialize()
end
