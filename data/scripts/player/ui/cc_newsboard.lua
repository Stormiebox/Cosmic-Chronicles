package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

local headlineList
local contentTextBox

local currentNewsArray = {}

if onClient() then

function CosmicChroniclesNewsBoard.initUI()
    if self.tab then return end
    local menu = PlayerWindow()
    self.tab = menu:createTab("Galactic News"%_t, "data/textures/icons/cc_galacticnews_rss.png", "Galactic News"%_t)
    self.tab.onShowFunction = "onShowWindow"
    self.tab.onSelectedFunction = "onShowWindow"
    menu:moveTabToTheRight(self.tab)

    local split = UIVerticalSplitter(Rect(self.tab.size), 10, 0, 0.35)
    headlineList = self.tab:createListBox(split.left)
    headlineList.onSelectFunction = "onNewsSelected"
    
    contentTextBox = self.tab:createMultiLineTextBox(split.right)
    contentTextBox.active = false
    
    headlineList:addEntry("Connecting to Galactic News Network..."%_t, 0)
    
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.initialize()
    CosmicChroniclesNewsBoard.initUI()
end

function CosmicChroniclesNewsBoard.onShowWindow()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onNewsSelected()
    if not headlineList then return end

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

function CosmicChroniclesNewsBoard.receiveNews(newsArray)
    currentNewsArray = newsArray or {}

    headlineList:clear()
    
    if #currentNewsArray == 0 then
        headlineList:addEntry("No broadcasts available at this time."%_t, 0)
    else
        for i, article in ipairs(currentNewsArray) do
            headlineList:addEntry("[" .. (article.category or "News"%_t) .. "] " .. (article.title or ""), i)
        end
    end
end

end -- end onClient

-- Server function that fetches the vault news and sends it to this specific player
function CosmicChroniclesNewsBoard.requestNewsSync()
    if not onServer() then return end
    print("[CCNewsBoard] Server VM received requestNewsSync from player " .. tostring(callingPlayer))
    
    -- Send a callback to the global Server. The vault news script listens to this and generates seed news if empty.
    -- This is a synchronous call. By the time it returns, news generation is complete!
    Server():sendCallback("onCCNewsSyncRequest", callingPlayer)
    
    -- Now safely fetch the data. No re-entrancy deadlock because the vault isn't calling us!
    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = vaultNews
    end
    
    print("[CCNewsBoard] Sending news back to client! News count: " .. tostring(#newsData))
    invokeClientFunction(Player(callingPlayer), "receiveNews", newsData)
end
callable(CosmicChroniclesNewsBoard, "requestNewsSync")

-- Called by Vault when a NEW article is published organically
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
    
    local player = Player()
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end

