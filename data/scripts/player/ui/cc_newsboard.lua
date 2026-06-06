package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

local tab
local headlineList
local contentTextBox

local currentNewsArray = {}

function CosmicChroniclesNewsBoard.initialize()
    if onClient() then
        -- Request news from server upon load
        invokeServerFunction("requestNewsSync")
    end
end

function CosmicChroniclesNewsBoard.initUI()
    local menu = PlayerWindow()
    
    -- Create a tab inside the Player Window
    tab = menu:createTab("News", "data/textures/icons/cc_galacticnews_rss.png", "Galactic News")
    
    local split = UIVerticalSplitter(Rect(vec2(0, 0), tab.size), 10, 0, 0.35)
    
    headlineList = tab:createListBox(split.left)
    contentTextBox = tab:createTextBox(split.right, "")
    contentTextBox.active = false -- read only
    contentTextBox.fontSize = 14
end

function CosmicChroniclesNewsBoard.onShowWindow()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.updateClient(timeStep)
    if not headlineList then return end
    
    -- Check if selection changed
    local selected = headlineList.selected
    if selected and selected >= 0 and currentNewsArray[selected + 1] then
        local article = currentNewsArray[selected + 1]
        local displayString = "==================================================\n\n"
        displayString = displayString .. "  " .. article.title .. "\n"
        displayString = displayString .. "  Category: " .. article.category .. "\n\n"
        displayString = displayString .. "==================================================\n\n"
        displayString = displayString .. article.content
        
        contentTextBox.text = displayString
    else
        contentTextBox.text = "Select a headline to read the full article."%_t
    end
end

-- Server function that forwards the vault news to this specific player
function CosmicChroniclesNewsBoard.requestNewsSync()
    if not onServer() then return end
    
    local ok, news = pcall(Server().invokeFunction, Server(), "server/cosmicvaultnews_server.lua", "getPublishedNews")
    -- Wait, if cosmicvaultnews_server.lua doesn't have getPublishedNews returning values (due to invokeFunction limits),
    -- we should just call it directly since they share the same Server() VM. Wait, invokeFunction doesn't return table data correctly across script contexts sometimes.
    -- Better way: The player script asks cosmicvaultnews_server.lua to push to them.
    local server = Server()
    pcall(server.invokeFunction, server, "server/cosmicvaultnews_server.lua", "syncPlayer", callingPlayer)
end
callable(CosmicChroniclesNewsBoard, "requestNewsSync")

function CosmicChroniclesNewsBoard.receiveNews(newsArray)
    if not onClient() then return end
    currentNewsArray = newsArray or {}
    
    headlineList:clear()
    for _, article in ipairs(currentNewsArray) do
        headlineList:addEntry("[" .. article.category .. "] " .. article.title)
    end
end
