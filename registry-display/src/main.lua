local TERM_X, TERM_Y = term.getSize()
local MONITOR_X, MONITOR_Y = peripheral.find("monitor").getSize()
local PROTOCOL = "registry"
local MASTER_ID = 1

--[[
    Function to transform a color index into a code for background colors.
]]
local function colorIndexToCode(i)
    i = tonumber(i)
    return 2 ^ (i - 1)
end

--[[
   Function to get the side that the monitor is attached to.
]]
local function getMonitorSide()
    names = peripheral.getNames()
	for i = 1, #names do
	    if peripheral.getType(names[i]) == "monitor" then
		    return names[i]
	    end
	end
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
printCentre("Ender Registry Display", 4, colours.cyan)
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

Manager:addProjector(Projector("monitor", "monitor", getMonitorSide()))

completeTask()

--[[
    TML is a custom markup language for Titanium aiming to drastically increase productivity and decrease the amount of Lua you write when
    designing your UI.

    The import function loads the TML file and adds all the nodes generated to `Manager`, which is our Application instance.
]]
Manager:importFromTML "registry-display/ui/master.tml"
completeTask()

--[[
    This local is a table that contains some commonly used assets. `Manager:query` allows us to use CSS like selectors
    to search all the nodes inside of our application and return the result.

    To speed the program up, we only query these things once and store the result in `app`.
]]
local app = {
    -- Here we import our theme file, this is the same sytnax as TML however it doesn't create nodes but instead allows styling (think, a CSS file).
    masterTheme = Theme.fromFile( "masterTheme", "registry-display/ui/master.theme" ),

    outerContainer = Manager:query "#outer_container".result[1],
    scrollContainer = Manager:query "#scroll_container".result[1],
}

completeTask()

-- We already imported our theme file inside our `app` local, however we haven't added it to our application yet. Doing so means the theme file will be applied
Manager:addTheme( app.masterTheme )
completeTask()

local function addEntryNode(nodeIndex, first_color, second_color, third_color, entry)
    -- Get the X and Y location of the next container based
    -- on the given index
    local containerX = 4
    if nodeIndex % 2 == 0 then
        containerX = MONITOR_X / 2 + 3
    end

    local height = 5

    local containerY = 2 + math.ceil((nodeIndex - 2) / 2) * (height + 1)

    -- Leave space between the borders of the screen and
    -- the other container
    local width = MONITOR_X / 2 - 6

    -- Create the container for this entry
    local container = Container(containerX, containerY, width, height)

    -- Create the name label
    container:addNode(Label(entry.name, 1, 1):set{
        colour = colours.cyan
    })

    -- Create the description container
    container:addNode(TextContainer(entry.desc, 1, 2, width, height - 1):set{
        colour = colours.grey
    })

    -- Create the color panes
    container:addNode(Pane(width - 5, 1, 2, 1):set{
        backgroundColour = colorIndexToCode(first_color)
    })
    container:addNode(Pane(width - 3, 1, 2, 1):set{
        backgroundColour = colorIndexToCode(second_color)
    })
    container:addNode(Pane(width - 1, 1, 2, 1):set{
        backgroundColour = colorIndexToCode(third_color)
    })

    app.scrollContainer:addNode(container)
end

local function updateContainer(registry)
    app.scrollContainer:clearNodes()

    local counter = 1
    for k1, v1 in pairs(registry) do
        for k2, v2 in pairs(v1) do
            for k3, entry in pairs(v2) do
                addEntryNode(counter, k1, k2, k3, entry)

                counter = counter + 1
            end
        end
    end
end

local function shutdown()
    Manager:stop()
    term.setBackgroundColour( 32768 )
    term.clear()
end

app.outerContainer:set{
    width = MONITOR_X,
    height = MONITOR_Y,
    backgroundColour = colours.white
}

Manager:registerHotkey("close", "leftCtrl-leftShift-t", function()
    shutdown()
end) -- Setup a hotkey that quickly exits program

completeTask()

-- Check for the response of the registry copy request
-- and update the registry if needed
Manager:addThread(Thread(function()
    while true do
        local senderId, message = rednet.receive(PROTOCOL)

        if message["type"] == "response" then
            if message["request"] == "registry copy" then
                if message["success"] then
                    local registry = message["registry"]
                    registry = textutils.serialize(registry)
                    registry = textutils.unserialize(registry)

                    updateContainer(registry)
                end
            end
        end
    end
end, false))

-- Schedule a function to retrieve a copy
-- of the registry periodically
Manager:schedule(function()
    local message = {
        type = "request",
        request = "registry copy"
    }

    rednet.send(MASTER_ID, message, PROTOCOL)
end, 2, true)

completeTask()

peripheral.find("modem", rednet.open)

-- We are ready to go. Any code after this function will not be executed until the application closes.
completeTask()
Manager:start()
