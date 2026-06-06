package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")

-- namespace CosmicChroniclesNewsBoard
CosmicChroniclesNewsBoard = {}
local self = CosmicChroniclesNewsBoard

local tab
local headlineList
local contentTextBox

local currentNewsArray = {}

if onClient() then

function CosmicChroniclesNewsBoard.initialize()
    local menu = PlayerWindow()
    
    -- Create a tab inside the Player Window
    tab = menu:createTab("Galactic News", "data/textures/icons/cc_galacticnews_rss.png", "Galactic News")
    tab.onShowFunction = "onShowWindow"
    tab.onSelectedFunction = "onShowWindow"
    
    menu:moveTabToTheRight(tab)

    local split = UIVerticalSplitter(Rect(tab.size), 10, 0, 0.35)
    
    headlineList = tab:createListBox(split.left)
    contentTextBox = tab:createTextBox(split.right, "")
    contentTextBox.active = false -- read only
    contentTextBox.fontSize = 14

    -- Request news from server upon load
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.onShowWindow()
    invokeServerFunction("requestNewsSync")
end

function CosmicChroniclesNewsBoard.updateClient(timeStep)
    if not headlineList then return end
    
    -- Check if selection changed
    local selected = headlineList.selected
    if selected and currentNewsArray[selected + 1] then
        local article = currentNewsArray[selected + 1]
        local displayString = "   ===== " .. article.title .. "\n\n"
        displayString = displayString .. "   Reported by: " .. article.author .. "\n"
        displayString = displayString .. "   Category: " .. article.category .. "\n\n"
        displayString = displayString .. article.content
        
        contentTextBox.text = displayString
    end
end

function CosmicChroniclesNewsBoard.receiveNews(newsArray)
    currentNewsArray = newsArray or {}
    
    headlineList:clear()
    for _, article in ipairs(currentNewsArray) do
        headlineList:addEntry("[" .. article.category .. "] " .. article.title)
    end
end

end -- end onClient

-- Server function that forwards the vault news to this specific player
function CosmicChroniclesNewsBoard.requestNewsSync()
    if not onServer() then return end
    
    local ok, news = pcall(Server().invokeFunction, Server(), "server/cosmicvaultnews_server.lua", "getPublishedNews")
    local server = Server()
    pcall(server.invokeFunction, server, "server/cosmicvaultnews_server.lua", "syncPlayer", callingPlayer)
end
callable(CosmicChroniclesNewsBoard, "requestNewsSync")

return CosmicChroniclesNewsBoard

