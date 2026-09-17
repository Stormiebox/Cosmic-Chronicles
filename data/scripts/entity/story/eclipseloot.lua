-- Migration shim for pre-v4 Eclipse lore entities. Loot is now snapshotted and receipted by
-- cc_blackbox.lua; this script deliberately performs no independent reward side effect.
function initialize()
    if onServer() then Entity():addScriptOnce("data/scripts/entity/cc_blackbox.lua") end
    terminate()
end
