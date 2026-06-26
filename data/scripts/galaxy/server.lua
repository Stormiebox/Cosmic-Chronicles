include("data/scripts/galaxy/server.lua")
local CosmicChronicles_old_init = initialize

function initialize(...)
    if CosmicChronicles_old_init then CosmicChronicles_old_init(...) end

    local CosmicChronicles = include("server/cosmicchronicles")
    if CosmicChronicles and CosmicChronicles.initialize then CosmicChronicles.initialize() end
end