-- Migration shim for sectors that persisted the pre-v4 destruction tracker.
function initialize()
    if onServer() then Sector():addScriptOnce("data/scripts/sector/cc_sector_observer.lua") end
    terminate()
end
