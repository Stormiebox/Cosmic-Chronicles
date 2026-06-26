include("data/scripts/player/init.lua")
package.path = package.path .. ";data/scripts/lib/?.lua"

if onServer() then
    local player = Player()
    player:addScriptOnce("data/scripts/player/background/cc_event_controller.lua")
    player:addScriptOnce("data/scripts/player/ui/cc_newsboard.lua")
    player:addScriptOnce("data/scripts/player/cosmicchroniclescodex.lua")
end
