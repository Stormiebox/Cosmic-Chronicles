package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

self.currentNewsArray = {}

-- ==========================================
-- CLIENT SIDE
-- ==========================================
if onClient() then

function CosmicChroniclesNewsBoard.initialize()
    local menu = PlayerWindow()
    self.tab = menu:createTab("Galactic News"%_t, "data/textures/icons/cc_galacticnews_rss.png", "Galactic News"%_t)
    self.tab.onShowFunction = "onShowWindow"
    self.tab.onSelectedFunction = "onShowWindow"
    
    local split = UIVerticalSplitter(Rect(self.tab.size), 10, 0, 0.35)
    
    self.headlineList = self.tab:createListBox(split.left)
    self.headlineList.onSelectFunction = "onNewsSelected"
    
    self.contentTextBox = self.tab:createMultiLineTextBox(split.right)
    
    self.headlineList:addEntry("Connecting to Galactic News Network..."%_t, 0)
    
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onShowWindow()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onNewsSelected(index)
    if not self.headlineList then return end
    
    local selectedValue = self.headlineList.selectedValue
    if not selectedValue then return end

    local article = self.currentNewsArray[selectedValue]
    if article then
        local displayString = "   ===== " .. (article.title or "Unknown"%_t) .. " =====\n\n"
        displayString = displayString .. "   Reported by: "%_t .. (article.author or "Unknown"%_t) .. "\n"
        displayString = displayString .. "   Category: "%_t .. (article.category or "Unknown"%_t) .. "\n\n"
        displayString = displayString .. (article.content or "")

        self.contentTextBox.text = displayString
    end
end

function CosmicChroniclesNewsBoard.receiveNews(newsArray)
    self.currentNewsArray = newsArray or {}
    
    if self.headlineList then
        self.headlineList:clear()
        
        if #self.currentNewsArray == 0 then
            self.headlineList:addEntry("No broadcasts available at this time."%_t, 0)
        else
            for i, article in ipairs(self.currentNewsArray) do
                self.headlineList:addEntry("[" .. (article.category or "News"%_t) .. "] " .. (article.title or ""), i)
            end
        end
    end
end

end -- end onClient()


-- ==========================================
-- SERVER SIDE
-- ==========================================

function CosmicChroniclesNewsBoard.requestNewsSync()
    if not onServer() then return end
    
    Server():sendCallback("onCCNewsSyncRequest", callingPlayer)
    
    local ok, vaultNews = Galaxy():invokeFunction("cosmicvaultnews_server.lua", "getNews")
    local newsData = {}
    if ok == 0 and type(vaultNews) == "table" then
        newsData = vaultNews
    end
    
    local player = Player(callingPlayer)
    if player then
        invokeClientFunction(player, "receiveNews", newsData)
    end
end
callable(CosmicChroniclesNewsBoard, "requestNewsSync")

function CosmicChroniclesNewsBoard.onNewsPublished()
    if not onServer() then return end
    deferredCallback(0.1, "deferredNewsSync")
end

function CosmicChroniclesNewsBoard.deferredNewsSync()
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


