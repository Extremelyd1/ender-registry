local TERM_X, TERM_Y = term.getSize()
local REGISTRY_FILE_NAME = "registry.cfg"
local LOG_FILE_NAME = "registry.log"
local PROTOCOL = "registry"
local MAX_LOG_SIZE = 20

local colorNames = {
    ["1"] = "White",
    ["2"] = "Orange",
    ["3"] = "Magenta",
    ["4"] = "Light Blue",
    ["5"] = "Yellow",
    ["6"] = "Lime",
    ["7"] = "Pink",
    ["8"] = "Gray",
    ["9"] = "Light Gray",
    ["10"] = "Cyan",
    ["11"] = "Purple",
    ["12"] = "Blue",
    ["13"] = "Brown",
    ["14"] = "Green",
    ["15"] = "Red",
    ["16"] = "Black",
}

local function colorIndexToCode(i)
    i = tonumber(i)
    return 2 ^ (i - 1)
end

local log = {}

if fs.exists(LOG_FILE_NAME) then
    local logFileHandle = fs.open(LOG_FILE_NAME, 'r')
    log = textutils.unserialize(logFileHandle.readAll())
end

local function saveLog()
    local logFileHandle = fs.open(LOG_FILE_NAME, 'w')
    logFileHandle.write(textutils.serialize(log))
    logFileHandle.close()
end

local function addLogEntry(entry)
    if table.maxn(log) < MAX_LOG_SIZE then
        table.insert(log, table.maxn(log) + 1, entry)
    else
        table.remove(log, 1)
        table.insert(log, MAX_LOG_SIZE, entry)
    end

    saveLog()
end

local registry = {}

if fs.exists(REGISTRY_FILE_NAME) then
    local registryFileHandle = fs.open(REGISTRY_FILE_NAME, 'r')
    registry = textutils.unserialize(registryFileHandle.readAll())
end

local function saveRegistry()
    local registryFileHandle = fs.open(REGISTRY_FILE_NAME, 'w')
    registryFileHandle.write(textutils.serialize(registry))
    registryFileHandle.close()
end

local function addRegistryEntry(info)
    local first_color = info["colors"]["1"]
    local second_color = info["colors"]["2"]
    local third_color = info["colors"]["3"]

    local name = info["details"]["name"]
    local desc = info["details"]["description"]

    if not registry[first_color] then
        registry[first_color] = {}
    end
    if not registry[first_color][second_color] then
        registry[first_color][second_color] = {}
    end
    if not registry[first_color][second_color][third_color] then
        registry[first_color][second_color][third_color] = {}
    end

    registry[first_color][second_color][third_color]["name"] = name
    registry[first_color][second_color][third_color]["desc"] = desc

    local log_entry = {
        type = "insert",
        first_color = first_color,
        second_color = second_color,
        third_color = third_color,
        name = name,
        description = desc
    }

    addLogEntry(log_entry)

    saveRegistry()
end

local function removeRegistryEntry(first_color, second_color, third_color, entry)
    if not registry[first_color] then
        return
    end
    if not registry[first_color][second_color] then
        return
    end
    if not registry[first_color][second_color][third_color] then
        return
    end

    -- Remove existing entry at the lowest level
    registry[first_color][second_color][third_color] = nil

    -- Check for empty subkeys to restore ordered registry
    local count = 0
    for _ in pairs(registry[first_color][second_color]) do count = count + 1 end
    if count == 0 then
        registry[first_color][second_color] = nil
    end
    count = 0
    for _ in pairs(registry[first_color]) do count = count + 1 end
    if count == 0 then
        registry[first_color] = nil
    end

    local log_entry = {
        type = "delete",
        first_color = first_color,
        second_color = second_color,
        third_color = third_color,
        name = entry.name,
        description = entry.desc
    }

    addLogEntry(log_entry)

    saveRegistry()
end

local function checkRegistry(first_color, second_color, third_color)
    if registry[first_color] == nil then
        return false
    end

    if registry[first_color][second_color] == nil then
        return false
    end

    if registry[first_color][second_color][third_color] == nil then
        return false
    end

    return true
end

term.setBackgroundColour( 1 )
term.clear()

local tasks = {
    {"Launching Titanium"},
    {"Instantiating Application"},
    {"Loading TML"},
    {"Loading Theme"},
    {"Applying Theme"},
    {"Registering callbacks"},
    {"Starting parallel thread"},
    {"Done"}
}

local function printCentre( text, y, col )
    if col then term.setTextColour( col ) end

    term.setCursorPos( math.floor( TERM_X / 2 - ( #text / 2 ) ), y )
    term.clearLine()
    term.write( text )
end

local function completeTask( task )
    for i = 1, #tasks do
        if not tasks[ i ][ 2 ] then
            tasks[ i ][ 2 ] = os.clock()

            local y = 9
            for i = 1, #tasks do
                local done = tasks[ i ][ 2 ]
                printCentre( tasks[ i ][ 1 ] .. ( done and " ["..done.."]" or "" ), y, done and colours.green or ( pre and colours.cyan ) or 256 )

                pre, y = done, y + 1
            end

            return
        end
    end
end

sleep( 0 )
printCentre("Ender Registry Master Console", 4, colours.cyan)
printCentre("Titanium GUI Powered", 5, colours.lightGrey)
printCentre("Loading", TERM_Y - 1, 128)

completeTask()

--[[
    An Application instance is the starting point of a Titanium application. It accepts 4 arguments: x, y, width and height.
    The default position and size was fine for my use case, so I passed no arguments inside the brackets.

    I did however want to adjust some other properties of the Application, so for that I used the `set` function and passed a
    key-value table. The key being the name of the property and the value being the value of the property.

    `:set` is available on all nodes as well and returns the object you called it on (in this case, Application) so you can chain other functions
    after it.
]]
Manager = Application():set {
    colour = 128,
    backgroundColour = 1,
    terminatable = true
}

completeTask()

--[[
    TML is a custom markup language for Titanium aiming to drastically increase productivity and descrease the amount of Lua you write when
    designing your UI.

    The import function loads the TML file and adds all the nodes generated to `Manager`, which is our Application instance.
]]
Manager:importFromTML "registry-master/ui/master.tml"
completeTask()

--[[
    This local is a table that contains some commonly used assets. `Manager:query` allows us to use CSS like selectors
    to search all the nodes inside of our application and return the result.

    To speed the program up, we only query these things once and store the result in `app`.
]]
local app = {
    -- Here we import our theme file, this is the same sytnax as TML however it doesn't create nodes but instead allows styling (think, a CSS file).
    masterTheme = Theme.fromFile( "masterTheme", "registry-master/ui/master.theme" ),

    pages = Manager:query "TabbedPageContainer".result[1],

    registryContainer = Manager:query "#registry_container".result[1],
    logContainer = Manager:query "#log_container".result[1],
}

completeTask()

-- Using our `app` local, switch the current page to 'color'.
app.pages:selectPage "registry_page"

-- We already imported our theme file inside our `app` local, however we haven't added it to our application yet. Doing so means the theme file will be applied
Manager:addTheme( app.masterTheme )
completeTask()

local function addLogNode(pageNodeSize)
    -- Get the Y location of the next container based
    -- on the last container in the log page
    local containerY = 2 + pageNodeSize * 2

    -- Leave a space between the side of the container
    -- and the scrollbar in case the parent is over-filled
    local width = TERM_X - 3

    -- Create the container for this entry
    local container = Container(2, containerY, width, 1)

    -- Create the +/- for insert/delete label
    container:addNode(Label("", 7, 1))

    -- Create the name label
    container:addNode(Label("", 9, 1):set{
        colour = colours.cyan
    })

    -- Create the color panes
    container:addNode(Pane(width - 11, 1, 2, 1))
    container:addNode(Pane(width - 9, 1, 2, 1))
    container:addNode(Pane(width - 7, 1, 2, 1))

    app.logContainer:addNode(container)
end

local function updateLogContainer()
    -- First check sizes to see if additional nodes need
    -- to be created
    local logSize = table.maxn(log)
    local containerSize
    if app.logContainer.nodes then
        containerSize = #app.logContainer.nodes
    else
        containerSize = 0
    end

    -- Remove abundant nodes
    while containerSize > logSize do
        local target = app.logContainer.nodes[containerSize]
        app.logContainer:removeNode(target)
        containerSize = containerSize - 1
        app.registryContainer:cacheContent()
    end

    -- Create the required nodes
    while logSize > containerSize do
        addLogNode(containerSize)
        containerSize = containerSize + 1
    end

    -- Update the contents of all nodes
    for i = 1, logSize do
        local entryContainer = app.logContainer.nodes[i]
        -- Inversely go through log entries to make sure
        -- that recent entries end up on top
        local entry = log[logSize - i + 1]

        local insertLabel = entryContainer.nodes[1]
        if entry.type == "insert" then
            insertLabel.colour = colours.lime
            insertLabel.text = "+"
        else
            insertLabel.colour = colours.red
            insertLabel.text = "-"
        end

        local nameLabel = entryContainer.nodes[2]
        nameLabel.text = entry.name

        local colorPane = entryContainer.nodes[3]
        colorPane.backgroundColour = colorIndexToCode(entry.first_color)

        colorPane = entryContainer.nodes[4]
        colorPane.backgroundColour = colorIndexToCode(entry.second_color)

        colorPane = entryContainer.nodes[5]
        colorPane.backgroundColour = colorIndexToCode(entry.third_color)
    end
end

local function addRegistryNode(pageNodeSize)
    -- Get the Y location of the next container based
    -- on the last container in the log page
    local containerY = 2 + pageNodeSize * 4

    -- Leave a space between the side of the container
    -- and the scrollbar in case the parent is over-filled
    local width = TERM_X - 3

    -- Create the container for this entry, height of 4
    -- 1 for name, 3 for description
    local container = Container(2, containerY, width, 4)

    -- Create the name label
    container:addNode(Label("", 1, 1):set{
        colour = colours.cyan
    })

    -- Create the description text container
    container:addNode(TextContainer("", 1, 2, width - 10, 2))

    -- Create the color panes
    container:addNode(Pane(width - 17, 1, 2, 1))
    container:addNode(Pane(width - 15, 1, 2, 1))
    container:addNode(Pane(width - 13, 1, 2, 1))

    -- Create delete button
    container:addNode(Button("Delete", width - 8, 2))

    app.registryContainer:addNode(container)
end

local function updateRegistryContainer()
    -- First check sizes to see if additional nodes need
    -- to be created
    local registrySize = 0
    for k1, v1 in pairs(registry) do
        for k2, v2 in pairs(v1) do
            for k3, v3 in pairs(v2) do
                registrySize = registrySize + 1
            end
        end
    end

    -- Clear nodes
    app.registryContainer:clearNodes()

    -- Create the required nodes
    for i = 1, registrySize do
        addRegistryNode(i - 1)
    end

    -- Update the contents of all nodes
    local counter = 1
    for k1, v1 in pairs(registry) do
        for k2, v2 in pairs(v1) do
            for k3, entry in pairs(v2) do
                local entryContainer = app.registryContainer.nodes[counter]

                local nameLabel = entryContainer.nodes[1]
                nameLabel.text = entry.name

                local descLabel = entryContainer.nodes[2]
                descLabel.text = entry.desc

                local colorPane = entryContainer.nodes[3]
                colorPane.backgroundColour = colorIndexToCode(k1)

                colorPane = entryContainer.nodes[4]
                colorPane.backgroundColour = colorIndexToCode(k2)

                colorPane = entryContainer.nodes[5]
                colorPane.backgroundColour = colorIndexToCode(k3)

                local button = entryContainer.nodes[6]

                button:set{ enabled = false }
                Manager:schedule(function()
                    button:set{ enabled = true }
                    button:on("trigger", function()
                        removeRegistryEntry(k1, k2, k3, entry)
                        updateRegistryContainer()
                        updateLogContainer()
                    end)
                end, 1)

                counter = counter + 1
            end
        end
    end
end

-- Update pages once manually
updateRegistryContainer()
updateLogContainer()

local function shutdown()
    Manager:stop()
    term.setBackgroundColour( 32768 )
    term.clear()
end

Manager:registerHotkey("close", "leftCtrl-leftShift-t", function()
    shutdown()
end) -- Setup a hotkey that quickly exits program

completeTask()

Manager:addThread(Thread(function()
    while true do
        local senderId, message = rednet.receive(PROTOCOL)

        if message["type"] == "request" then
            local reponseMessage

            if message["request"] == "registry check" then
                local first_color = message["first_color"]
                local second_color = message["second_color"]
                local third_color = message["third_color"]

                if checkRegistry(first_color, second_color, third_color) then
                    responseMessage = {
                        type = "response",
                        request = "registry check",
                        success = false
                    }
                else
                    responseMessage = {
                        type = "response",
                        request = "registry check",
                        success = true
                    }
                end
            elseif message["request"] == "registry entry" then
                local first_color = message["info"]["colors"]["1"]
                local second_color = message["info"]["colors"]["2"]
                local third_color = message["info"]["colors"]["3"]

                if checkRegistry(first_color, second_color, third_color) then
                    responseMessage = {
                        type = "response",
                        request = "registry entry",
                        success = false
                    }
                else
                    addRegistryEntry(message["info"])

                    updateRegistryContainer()
                    updateLogContainer()

                    responseMessage = {
                        type = "response",
                        request = "registry entry",
                        success = true
                    }
                end
            elseif message["request"] == "registry copy" then
                responseMessage = {
                    type = "response",
                    request = "registry copy",
                    success = true,
                    registry = registry
                }
            end

            rednet.send(senderId, responseMessage, PROTOCOL)
        end
    end
end, false))

completeTask()

peripheral.find("modem", rednet.open)

-- We are ready to go. Any code after this function will not be executed until the application closes.
completeTask()
Manager:start()
