package.path = package.path .. ";data/scripts/lib/?.lua"

if onServer() then
    local sector = Sector()

    if sector then
        sector:addScriptOnce("data/scripts/sector/cc_destructiontracker.lua")
    end
end
