local TERM_X, TERM_Y = term.getSize()
local PROTOCOL = "registry"
local MASTER_ID = 1

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

local function addRegistryEntry(info)
    local message = {
        type = "request",
        request = "registry entry",
        info = info
    }

    rednet.send(MASTER_ID, message, PROTOCOL)
end

local function checkRegistry(first_color, second_color, third_color)
    local message = {
        type = "request",
        request = "registry check",
        first_color = first_color,
        second_color = second_color,
        third_color = third_color
    }

    rednet.send(MASTER_ID, message, PROTOCOL)
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
printCentre("Ender Registry", 4, colours.cyan)
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
Manager:importFromTML "registry-client/ui/master.tml"
completeTask()

--[[
    This local is a table that contains some commonly used assets. `Manager:query` allows us to use CSS like selectors
    to search all the nodes inside of our application and return the result.

    To speed the program up, we only query these things once and store the result in `app`.
]]
local app = {
    -- Here we import our theme file, this is the same sytnax as TML however it doesn't create nodes but instead allows styling (think, a CSS file).
    masterTheme = Theme.fromFile( "masterTheme", "registry-client/ui/master.theme" ),

    -- Grab our page container which was created in our TML file. This page container has two pages, which we will get into later
    pages = Manager:query "#mainContainer".result[1],

    color_panes = {
        ["1"] = Manager:query "#first_color_pane".result[1],
        ["2"] = Manager:query "#second_color_pane".result[1],
        ["3"] = Manager:query "#third_color_pane".result[1],
    },

    color_confirm_message = Manager:query "#color_confirm_message".result[1],

    name_input = Manager:query "#name_input".result[1],
    desc_input = Manager:query "#desc_input".result[1],

    details_confirm_message = Manager:query "#details_confirm_message".result[1],

    reset_button = Manager:query "#reset_button".result[1],
    exit_button = Manager:query "#exit_button".result[1],

    color_next_button = Manager:query "#color_next_button".result[1],
    details_next_button = Manager:query "#details_next_button".result[1],
    back_button = Manager:query "#back_button".result[1],
    done_button = Manager:query "#done_button".result[1],

    finish_message = Manager:query "#finish_message".result[1],

    name_display = Manager:query "#name_display".result[1],
    desc_display = Manager:query "#description_display".result[1],
    color_display = Manager:query "#color_display".result[1],

    info = {},

    resetting = false,
}

completeTask()

-- Using our `app` local, switch the current page to 'color'.
app.pages:selectPage "colors"

-- We already imported our theme file inside our `app` local, however we haven't added it to our application yet. Doing so means the theme file will be applied
Manager:addTheme( app.masterTheme )
completeTask()

local function shutdown()
    Manager:stop()
    term.setBackgroundColour( 32768 )
    term.clear()
end

local function reset()
    app.info = {}

    app.color_panes["1"]:set{ backgroundColour = colours.lightGrey }
    app.color_panes["2"]:set{ backgroundColour = colours.lightGrey }
    app.color_panes["3"]:set{ backgroundColour = colours.lightGrey }

    Manager:query ".color_select":set{ selectedOption = false }

    app.color_confirm_message.text = ""

    app.name_input.value = ""
    app.name_input:setChanged(true)

    app.desc_input.text = ""

    app.color_next_button:set{ enabled = false }
    app.details_next_button:set{ enabled = false }

    app.finish_message.text = ""

    app.back_button:set{ enabled = true }

    app.done_button:set{ enabled = true }

    app.pages:selectPage "colors"

    app.resetting = false
end

--[[
    This is the first time we have used ':on', so what exactly does it do?

    First, we query the application for something with an id of 'exit_button'. Titanium will search your application and return a
    `NodeQuery` instance which we can use to access the results. Instead of accessing the results directly, we use the NodeQuery
    shortcut feature to apply changes straight away.

    Calling ':on' tells Titanium to bind an event listener to all the nodes it found, in our case this is just one. We tell Titanium 'on trigger, run this function'.
    Trigger means the node was... triggered. In this case, the node we got is a Button so it means when the button is clicked.
]]
app.exit_button:on( "trigger", function( self )
    -- Our exit button has been clicked. This means the button is enabled, and therefore the 'yes' checkbox was selected
    shutdown()
end)

-- The 'Next' or 'Back' button was clicked (depending on the selected page). Swap the page.
-- When the page swaps, different content will be displayed. This is defined in the TML file
Manager:query ".page_change":on("trigger", function( self )
    app.pages:selectPage( self.targetPage )
end)

Manager:query ".color_select":on( "change", function( self, selectedOption )
    if app.resetting then return end

    local col = selectedOption[2]
    local index = self.colorIndex

    app.color_panes[index]:set{ backgroundColour = colorIndexToCode(col) }

    -- Create colors entry in app.info
    if not app.info["colors"] then
        app.info["colors"] = {}
    end

    -- Populate this index in the colors entry
    app.info["colors"][index] = col

    local first_color = app.info["colors"]["1"]
    local second_color = app.info["colors"]["2"]
    local third_color = app.info["colors"]["3"]

    if first_color and second_color and third_color then
        -- All colors have been set
        -- Check whether this color has been used already
        app.reset_button:set{ enabled = false }
        Manager:query ".color_select":set{ enabled = false }

        app.color_confirm_message.colour = colours.grey
        app.color_confirm_message.text = "Checking availability..."

        checkRegistry(first_color, second_color, third_color)
    end
end)

app.color_confirm_message.text = ""

app.reset_button:on("trigger", function()
    app.resetting = true

    reset()
end)

local function checkDetails()
    if string.len(app.desc_input.text) > tonumber(app.desc_input.limit) then
        app.details_next_button:set{ enabled = false }

        app.details_confirm_message.text = "Description is too long!"
        return
    else
        app.details_confirm_message.text = ""
    end

    if app.name_input.value == "" or app.desc_input.text == "" then
        app.details_next_button:set{ enabled = false }
        -- Return early because some input field is not set yet
        return
    end

    -- Create details entry in app.info
    if not app.info["details"] then
        app.info["details"] = {}
    end

    -- Populate all details in entry
    app.info["details"]["name"] = app.name_input.value
    app.info["details"]["description"] = app.desc_input.text

    -- Enable next button
    app.details_next_button:set{ enabled = true }

    return
end

app.details_next_button:on( "trigger", function()
    app.name_display.text = app.info["details"]["name"]
    app.desc_display.text = app.info["details"]["description"]

    local color_text = colorNames[app.info["colors"]["1"]] .. ", "
    color_text = color_text .. colorNames[app.info["colors"]["2"]] .. ", "
    color_text = color_text .. colorNames[app.info["colors"]["3"]]

    app.color_display.text = color_text
end)

app.details_confirm_message.text = ""

app.finish_message.text = ""

app.done_button:on( "trigger", function()
    app.back_button:set{ enabled = false }
    app.done_button:set{ enabled = false }

    app.finish_message.colour = colours.grey
    app.finish_message.text = "Processing information..."

    addRegistryEntry(app.info)
end)

-- Remove trigger callbacks from tabs of TabbedPageContainer
local nodes = app.pages.tabContainer.nodes[1].nodes
for i = 1, #nodes do
    nodes[i].callbacks[ "trigger" ] = {}
end

Manager:registerHotkey("close", "leftCtrl-leftShift-t", function()
    app.exit_button:set{ visible = not app.exit_button.visible }
    app.exit_button:set{ enabled = not app.exit_button.enabled }
end) -- Setup a hotkey that enables the exit button

completeTask()

--[[
    This thread runs alongside the Application thread, allowing parallel programming from inside Titanium.

    This thread sets a loop that yields for events. When an event is received, it is a Titanium event. We check if the event is a 'key' event.
    If the key was pressed down we highlight that part of the hotkey by adding the held class to the label.

    If the key was released, we remove the class. The Theme file uses this theme to highlight the label when the 'held' class is present
]]
Manager:addThread(Thread(function()
    while true do -- Wait for events indefinitely
        local event = coroutine.yield() -- Wait for events
        if event.main == "KEY" then
            -- Check the details tab every time a key is pressed
            checkDetails()
        end
    end
end, true)) -- This true value tells Titanium to give the thread Titanium events, NOT CC events.

Manager:addThread(Thread(function()
    while true do
        local senderId, message = rednet.receive(PROTOCOL)

        if message["type"] == "response" then
            if message["request"] == "registry check" then
                if message["success"] then
                    app.color_confirm_message.colour = colours.lime
                    app.color_confirm_message.text = "This color code is valid!"

                    app.color_next_button:set{ enabled = true }
                else
                    app.color_confirm_message.colour = colours.red
                    app.color_confirm_message.text = "This color code is already in use!"

                    app.color_next_button:set{ enabled = false }
                end

                app.reset_button:set{ enabled = true }

                Manager:query ".color_select":set{ enabled = true }
            elseif message["request"] == "registry entry" then
                if message["success"] then
                    app.finish_message.colour = colours.lime
                    app.finish_message.text = "Information has been registered"

                    app.resetting = true

                    Manager:schedule(function()
                        reset()
                    end, 2)
                else
                    app.finish_message.colour = colours.red
                    app.finish_message.text = "Something went wrong, please try again later"
                end
            end
        end
    end
end, false))

completeTask()

peripheral.find("modem", rednet.open)

-- We are ready to go. Any code after this function will not be executed until the application closes.
completeTask()
Manager:start()
