package.path = package.path .. ";data/scripts/lib/?.lua"

-- namespace CCVanillaNews
CCVanillaNews = {}

function CCVanillaNews.initialize()
    if onServer() then
        Server():registerCallback("onCCNewsRequestSeed", "onSeedNews")
    end
end

function CCVanillaNews.onSeedNews()
    local server = Server()
    
    -- 1. Boss Defeats
    if server:getValue("swoks_beaten") then
        server:sendCallback("onCCNewsPublishArticle", {
            title = "Pirate Warlord Swoks Assassinated!",
            category = "Galactic Milestone",
            content = "The notorious pirate warlord known as 'Swoks' has been defeated. Independent pilots have claimed the massive bounty, bringing a temporary peace to the outer rim."
        })
    end

    if server:getValue("big_ai_kill_counter") and server:getValue("big_ai_kill_counter") > 0 then
        server:sendCallback("onCCNewsPublishArticle", {
            title = "Rogue A.I. Supercomputer Dismantled",
            category = "Galactic Milestone",
            content = "The terrifying machine intelligence known only as 'The A.I.' has been destroyed. Fragments of its processing core are already appearing on black markets."
        })
    end

    if server:getValue("bottan_beaten") then
        server:sendCallback("onCCNewsPublishArticle", {
            title = "Bottan's Smuggling Ring Busted!",
            category = "Galactic Milestone",
            content = "The infamous smuggler Bottan has finally been brought to justice. Faction security forces report a massive drop in black market shipments."
        })
    end

    if server:getValue("mad_science_beaten") then
        server:sendCallback("onCCNewsPublishArticle", {
            title = "M.A.D. Science Lab Destroyed!",
            category = "Galactic Milestone",
            content = "A secretive mobile laboratory conducting deeply unethical experiments has been eradicated. Authorities refuse to comment on the technology recovered."
        })
    end

    -- 2. Player Achievements
    for _, player in pairs({server:getOnlinePlayers()}) do
        if player:getValue("pirate_hideout_destroyed") or player:getValue("tutorial_pirateraid_accomplished") then
            server:sendCallback("onCCNewsPublishArticle", {
                title = "Pirate Stronghold Eradicated",
                category = "Military Action",
                content = string.format("A heavily fortified pirate sector was completely wiped out by Commander %s. Local trade routes are seeing a massive resurgence in traffic.", player.name)
            })
        end
    end
end
