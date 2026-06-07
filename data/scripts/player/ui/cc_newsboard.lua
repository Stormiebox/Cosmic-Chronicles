package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")

-- Client-side UI Variables
local tab
local headlineList
local contentTextBox
local currentNewsArray = {}

-- ==========================================
-- CLIENT SIDE
-- ==========================================
if onClient() then

-- Avorion engine callback. Must be global. Used for building UI components.
function initUI()
    local menu = PlayerWindow()
    -- Create the tab
    tab = menu:createTab("Galactic News"%_t, "data/textures/icons/cc_galacticnews_rss.png", "Galactic News"%_t)
    
    local split = UIVerticalSplitter(Rect(tab.size), 10, 0, 0.35)
    
    -- List box for headlines
    headlineList = tab:createListBox(split.left)
    headlineList.onSelectFunction = "onNewsSelected"
    
    -- TextBox for the actual news content
    contentTextBox = tab:createMultiLineTextBox(split.right)
    -- We cannot disable it otherwise it might cause MCM glitches, we just clear it.
    -- To prevent typing we can leave active as true but handle the input differently or just rely on standard UI rules
    
    headlineList:addEntry("Connecting to Galactic News Network..."%_t, 0)
    
    -- Request initial sync from server side
    invokeServerFunction("requestNewsSync")
end

-- Engine callback
function onShowWindow()
    invokeServerFunction("requestNewsSync")
end

-- Engine callback for tab interactions (sometimes triggers instead of onShowWindow)
function onSelectWindow()
    invokeServerFunction("requestNewsSync")
end

-- Hook the ListBox selection event
-- We need to attach this manually via a custom callback in the engine or define it as the onSelectFunction
-- But wait, in initUI we must assign it:
function initialize()
    -- initialize is mostly for logical setup, UI setup is exclusively in initUI()
end

function onNewsSelected(index)
    if not headlineList then return end
    
    -- index is passed by Avorion's ListBox callback, but let's grab it directly
    local selectedValue = headlineList.selectedValue
    if not selectedValue then return end

    local article = currentNewsArray[selectedValue]
    if article then
        local displayString = "   ===== " .. (article.title or "Unknown"%_t) .. " =====\n\n"
        displayString = displayString .. "   Reported by: "%_t .. (article.author or "Unknown"%_t) .. "\n"
        displayString = displayString .. "   Category: "%_t .. (article.category or "Unknown"%_t) .. "\n\n"
        displayString = displayString .. (article.content or "")

        contentTextBox.text = displayString
    end
end

function receiveNews(newsArray)
    currentNewsArray = newsArray or {}
    
    if headlineList then
        headlineList:clear()
        
        if #currentNewsArray == 0 then
            headlineList:addEntry("No broadcasts available at this time."%_t, 0)
        else
            for i, article in ipairs(currentNewsArray) do
                headlineList:addEntry("[" .. (article.category or "News"%_t) .. "] " .. (article.title or ""), i)
            end
        end
    end
end

end -- end onClient()


-- ==========================================
-- SERVER SIDE
-- ==========================================

-- Client asks server script for news
function requestNewsSync()
    if not onServer() then return end
    
    -- We ping the vault to wake up / request a seed if it's completely empty.
    Server():sendCallback("onCCNewsSyncRequest", callingPlayer)
    
    -- We pull the data directly and safely from the global Vault script.
    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = vaultNews
    end
    
    -- Send directly to the client that requested it
    local player = Player(callingPlayer)
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end
callable(nil, "requestNewsSync")

-- Invoked by the cosmicvaultnews_server.lua when an article is published organically
function onNewsPublished()
    if not onServer() then return end
    -- We use a deferred callback to fetch the news on the next tick
    -- This prevents re-entrant invokeFunction deadlocks between VM states!
    deferredCallback(0.1, "deferredNewsSync")
end

function deferredNewsSync()
    if not onServer() then return end
    
    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = vaultNews
    end
    
    -- We broadcast down to our own client UI
    local player = Player()
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end
