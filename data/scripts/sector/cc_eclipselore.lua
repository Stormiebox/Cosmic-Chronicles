-- Migration shim for sectors that persisted the pre-v4 random Eclipse spawner. Verified
-- Ascendancy News v2 evidence now creates lore events through the Chronicle coordinator.
function initialize()
    terminate()
end
