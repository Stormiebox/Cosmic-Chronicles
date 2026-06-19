package.path = package.path .. ";data/scripts/lib/?.lua"

local cv_news = include("cosmicvaultnews")

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
        if cv_news.publishArticle then
        cv_news.publishArticle({
            title = "Pirate Warlord Swoks Assassinated!",
            category = "Galactic Milestone",
            content = "The notorious pirate warlord known as 'Swoks' has been defeated. Independent pilots have claimed the massive bounty, bringing a temporary peace to the outer rim."
        })
        end
    end

    if server:getValue("big_ai_kill_counter") and server:getValue("big_ai_kill_counter") > 0 then
        if cv_news.publishArticle then
        cv_news.publishArticle({
            title = "Rogue A.I. Supercomputer Dismantled",
            category = "Galactic Milestone",
            content = "The terrifying machine intelligence known only as 'The A.I.' has been destroyed. Fragments of its processing core are already appearing on black markets."
        })
        end
    end

    if server:getValue("last_killed_laser_boss") then
        if cv_news.publishArticle then
        cv_news.publishArticle({
            title = "Project Beta Neutralized",
            category = "Galactic Milestone",
            content = "A massive experimental laser dreadnought known as 'Project Beta' has been destroyed. Authorities are investigating its origins."
        })
        end
    end

    -- 2. Player-tracked Boss Achievements & Player Actions
    for _, player in pairs({server:getOnlinePlayers()}) do
        if player:getValue("last_killed_bottan") then
            if cv_news.publishArticle then
        cv_news.publishArticle({
                title = "Bottan's Smuggling Ring Busted!",
                category = "Galactic Milestone",
                content = string.format("The infamous smuggler Bottan has finally been brought to justice by Commander %s. Faction security forces report a massive drop in black market shipments.", player.name)
            })
        end
            -- Prevent duplicate news if multiple players killed him
            player:setValue("last_killed_bottan", nil) 
        end

        if player:getValue("last_killed_scientist") then
            if cv_news.publishArticle then
        cv_news.publishArticle({
                title = "M.A.D. Science Lab Destroyed!",
                category = "Galactic Milestone",
                content = string.format("A secretive mobile laboratory conducting deeply unethical experiments has been eradicated by Commander %s. Authorities refuse to comment on the technology recovered.", player.name)
            })
        end
            player:setValue("last_killed_scientist", nil)
        end
        
        if player:getValue("last_killed_the4") then
            if cv_news.publishArticle then
        cv_news.publishArticle({
                title = "The Brotherhood Shattered",
                category = "Galactic Milestone",
                content = string.format("The elusive cult known as 'The Brotherhood', or 'The 4', has been decimated by Commander %s. Their mysterious artifact has been recovered.", player.name)
            })
        end
            player:setValue("last_killed_the4", nil)
        end
        
        if player:getValue("wormhole_guardian_destroyed") then
            if cv_news.publishArticle then
        cv_news.publishArticle({
                title = "Xsotan Wormhole Guardian Defeated!",
                category = "Galactic Milestone",
                content = string.format("Incredible reports are flooding in! Commander %s has successfully destroyed the massive Xsotan Guardian protecting the galactic core. The barrier to the center of the galaxy is opening!", player.name)
            })
        end
            if not server:getValue("cc_news_whg_published") then
                server:setValue("cc_news_whg_published", true)
            end
        end

        if player:getValue("pirate_hideout_destroyed") or player:getValue("tutorial_pirateraid_accomplished") then
            if not player:getValue("cc_news_pirate_hideout_published") then
            if cv_news.publishArticle then
                cv_news.publishArticle({
                    title = "Pirate Stronghold Eradicated",
                    category = "Military Action",
                    content = string.format("A heavily fortified pirate sector was completely wiped out by Commander %s. Local trade routes are seeing a massive resurgence in traffic.", player.name)
                })
            end
                player:setValue("cc_news_pirate_hideout_published", true)
            end
        end
    end
end

function initialize()
    CCVanillaNews.initialize()
end


-- Global Event Callbacks
function onSeedNews(...)
    if CCVanillaNews.onSeedNews then return CCVanillaNews.onSeedNews(...) end
end
