
if onServer() then
    local entity = Entity()
    if entity.isStation then
        if not entity:getValue("cc_station_type") then
            local stationType = "generic"
            if entity:hasScript("shipyard.lua") then
                stationType = "shipyard"
            elseif entity:hasScript("repairdock.lua") then
                stationType = "repairdock"
            elseif entity:hasScript("equipmentdock.lua") then
                stationType = "equipmentdock"
            elseif entity:hasScript("militaryoutpost.lua") then
                stationType = "militaryoutpost"
            elseif entity:hasScript("smugglersmarket.lua") then
                stationType = "smugglersmarket"
            elseif entity:hasScript("casino.lua") then
                stationType = "casino"
            elseif entity:hasScript("scrapyard.lua") then
                stationType = "scrapyard"
            elseif entity:hasScript("researchstation.lua") then
                stationType = "researchstation"
            elseif entity:hasScript("turretfactory.lua") then
                stationType = "turretfactory"
            elseif entity:hasScript("tradingpost.lua") then
                stationType = "tradingpost"
            elseif entity:hasScript("resourcedepot.lua") then
                stationType = "resourcedepot"
            elseif entity:hasScript("fighterfactory.lua") then
                stationType = "fighterfactory"
            end
            entity:setValue("cc_station_type", stationType)
        end
        entity:addScriptOnce("data/scripts/entity/cosmicchronicles_rumormonger.lua")
    end
end
