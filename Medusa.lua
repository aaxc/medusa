Medusa = {
    -- Main info
    name = "Medusa",
    version = "1.2.0",
    author = "@Aaxc",
    characterId = GetCurrentCharacterId(),

    -- Assistance settings
    inCombat = false,
    location = GetMapName(),
    debug = false,
    debugInfo = "",
    debugTime = 0,

    -- Variable data
    variableVersion = 3,

    -- Default settings
    Default = {
        Location = CENTER,
        OffsetX = -175,
        OffsetY = -150,
        lockBar = true,
        kiteWidth = 350,
        kiteHeight = 35,
        kiteColor = { 74, 20, 140, 1 },
    },

    -- Combat exit timer
    exitCombat = 0
}

-------------------------------------------------------------------------------------------------
-- Libraries --
-------------------------------------------------------------------------------------------------
local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")

-------------------------------------------------------------------------------------------------
-- OnAddOnLoaded  --
-------------------------------------------------------------------------------------------------
function Medusa.OnAddOnLoaded(event, addonName)
    if addonName ~= Medusa.name then
        return
    end

    Medusa:Initialize(0, "")
end

-------------------------------------------------------------------------------------------------
-- OnPlayerCombatState  --
-------------------------------------------------------------------------------------------------
function Medusa.OnPlayerCombatState(event, inCombat)
    -- The ~= operator is "not equal to" in Lua.
    if inCombat ~= Medusa.inCombat then
        -- The player's state has changed. Update the stored state...
        Medusa.inCombat = inCombat
        Medusa.location = GetMapName()
        EVENT_MANAGER:UnregisterForUpdate('ExitDelay')
    end

    -- Check location and make action
    if inCombat then
        -- Entering combat
        if Medusa.location == "Cloudrest" then
            Medusa.InitCloudrest()
        else
            Medusa.StopAllCombatEvents()
        end
    else
        Medusa.exitCombat = tonumber(GetTimeStamp())
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:RegisterForUpdate('ExitDelay', 1000, Medusa.QueueStopAllCombatEvents)
    end
end

-------------------------------------------------------------------------------------------------
-- Adds combat queue for 5s after exit
-------------------------------------------------------------------------------------------------
function Medusa.QueueStopAllCombatEvents()
    local current = tonumber(GetTimeStamp())
    local remaining = current - Medusa.exitCombat

    -- Stop all combat timers, if more then 5 secods have passed
    if remaining > 5 then
        Medusa.StopAllCombatEvents()
        EVENT_MANAGER:UnregisterForUpdate('ExitDelay')
    end
end

-------------------------------------------------------------------------------------------------
-- Stop all events, when combat ends  --
-------------------------------------------------------------------------------------------------
function Medusa.StopAllCombatEvents()
    -- Reset trials
    Medusa.Cloudrest.Reset()

    -- Stop events
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName)
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Kite.name)
    EVENT_MANAGER:UnregisterForEvent(Medusa.Cloudrest.name)
end


-------------------------------------------------------------------------------------------------
-- Initialize Medusa --
-------------------------------------------------------------------------------------------------
function Medusa:Initialize()
    -- Set combat state
    Medusa.inCombat = IsUnitInCombat("player")

    -- Load saved savedVariables
    Medusa.savedVariables = ZO_SavedVars:NewAccountWide("MedusaVars", Medusa.variableVersion, nil, Medusa.Default)

    -- Adds settings menu
    Medusa.CreateSettingsWindow()

    -- Position Break Bar and hide for now
    MedusaWindow:ClearAnchors()
    MedusaWindow:SetAnchor(TOPLEFT, GuiRoot, Medusa.savedVariables.MedusaWindowLocation, Medusa.savedVariables.MedusaWindowOffsetX, Medusa.savedVariables.MedusaWindowOffsetY)
    MedusaWindow:SetHidden(true)

    -- Position Portal timer and hide for now
    PortalWindow:ClearAnchors()
    PortalWindow:SetAnchor(TOPLEFT, GuiRoot, Medusa.savedVariables.PortalWindowLocation, Medusa.savedVariables.PortalWindowOffsetX, Medusa.savedVariables.PortalWindowOffsetY)
    PortalWindow:SetHidden(true)

    -- Position Portal timer and hide for now
    BigPortalWindow:ClearAnchors()
    BigPortalWindow:SetAnchor(TOPLEFT, GuiRoot, Medusa.savedVariables.BigPortalWindowLocation, Medusa.savedVariables.BigPortalWindowOffsetX, Medusa.savedVariables.BigPortalWindowOffsetY)
    BigPortalWindow:SetHidden(true)

    -- Position Kite timer and hide for now
    KiteWindow:ClearAnchors()
    KiteWindow:SetAnchor(TOPLEFT, GuiRoot, Medusa.savedVariables.KiteWindowLocation, Medusa.savedVariables.KiteWindowOffsetX, Medusa.savedVariables.KiteWindowOffsetY)
    KiteWindow:SetHidden(true)

    EVENT_MANAGER:UnregisterForEvent(Medusa.name, EVENT_ADD_ON_LOADED)
end

-------------------------------------------------------------------------------------------------
-- Show/hide bars for debug options  --
-------------------------------------------------------------------------------------------------
function Medusa.DebugCommand(extra)
    -- Get parameter data
    local i = 0
    for k in string.gmatch(extra, "%S+") do
        i = i + 1
        if i == 2 then
            -- check if stop command given
            if k == "show" then
                Medusa.debug = true
                d('Medusa debug ON')
            end

            if k == "hide" then
                Medusa.debug = false
                d('Medusa debug OFF')
            end
        end
    end
end

-------------------------------------------------------------------------------------------------
-- Manage slash commands --
-------------------------------------------------------------------------------------------------
function Medusa.SlashCommands(extra)
    local i = 0
    -- Get general options
    for k in string.gmatch(extra, "%S+") do
        i = i + 1
        if i == 1 then
            -- Break command
            if k == "break" then
                Medusa.BreakCommand(extra)
                -- Debug command
            elseif k == "debug" then
                Medusa.DebugCommand(extra)
            end
        end
    end
end

-------------------------------------------------------------------------------------------------
-- Manage slash commands --
-------------------------------------------------------------------------------------------------
function Medusa.CreateSettingsWindow()
    local panelData = {
        type = "panel",
        name = "Medusa",
        displayName = "Medusa Trial helper",
        author = "|c8BC34AAaxc|r",
        version = Medusa.version,
        slashCommand = "/mdsettings",
        registerForRefresh = true,
        registerForDefaults = true,
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel("Aaxc_Medusa", panelData)

    -- @TODO Load Language strings !!!!!
    -- @TODO Move this into settins LUA for easier reading

    local optionsData = {
        {
            type = "header",
            name = "General"
        },
        {
            type = "checkbox",
            name = "Lock bars",
            tooltip = "When OFF, bars are shown and unlocked and can be dragged around",
            getFunc = function() return Medusa.savedVariables.lockBar end,
            setFunc = function(newValue)
                Medusa.savedVariables.lockBar = newValue
                Medusa.BreakShowBars(not newValue)
                Medusa.CloudrestShowBars(not newValue)
                Medusa.CloudrestUnLockBars(not newValue)
            end,
        },
        {
            type = "header",
            name = "Trials"
        },
        {
            type = "description",
            text = "Here you can configure different trial settings. What you want or don't want to see and what size bars and colors you want to see."
        },
        {
            type = "submenu",
            name = "Cloudrest",
            tooltip = "Allows you to configure Coudrest settings",
            controls = {
                {
                    type = "header",
                    name = "Kite - Crushing darkness"
                },
                {
                    type = "checkbox",
                    name = "Show Crushing Darkness bar",
                    tooltip = "When ON, the Kite bar will be shown and can be adjusted",
                    default = true,
                    getFunc = function() return Medusa.savedVariables.kiteShow end,
                    setFunc = function(newValue) Medusa.savedVariables.kiteShow = newValue end,
                },
                {
                    type = "slider",
                    name = "Select Width",
                    tooltip = "Adjusts the width of the kite bar.",
                    min = 200,
                    max = 500,
                    step = 1,
                    default = 350,
                    getFunc = function() return Medusa.savedVariables.kiteWidth end,
                    setFunc = function(newValue)
                        Medusa.savedVariables.kiteWidth = newValue
                        Medusa.KiteSetBarSize(newValue, Medusa.savedVariables.kiteHeight)
                    end,
                },
                {
                    type = "slider",
                    name = "Select Height",
                    tooltip = "Adjusts the height of the kite bar.",
                    min = 25,
                    max = 50,
                    step = 1,
                    default = 35,
                    getFunc = function() return Medusa.savedVariables.kiteHeight end,
                    setFunc = function(newValue)
                        Medusa.savedVariables.kiteHeight = newValue
                        Medusa.KiteSetBarSize(Medusa.savedVariables.kiteWidth, newValue)
                    end,
                },
                {
                    type = "colorpicker",
                    name = "Select Color",
                    tooltip = "Changes the color of the kite bar.",
                    getFunc = function() return unpack( Medusa.savedVariables.kiteColor ) end,
                    setFunc = function(r,g,b,a)
                        local alpha = KiteWindowStatusBar:GetAlpha()
                        Medusa.savedVariables.kiteColor = { r, g, b, a}
                        KiteWindowStatusBar:SetColor( r,  g,  b,  a)
                        KiteWindowStatusBar:SetMinMax(0, 1)
                        KiteWindowStatusBar:SetValue(1)
                    end,
                },
            },
        }
    }
    LAM2:RegisterOptionControls("Aaxc_Medusa", optionsData)
end

-------------------------------------------------------------------------------------------------
-- Command requests Methods  --
-------------------------------------------------------------------------------------------------
-- General events and commands
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_PLAYER_COMBAT_STATE, Medusa.OnPlayerCombatState)
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_ADD_ON_LOADED, Medusa.OnAddOnLoaded)
SLASH_COMMANDS["/md"] = function(extra)
    Medusa.SlashCommands(extra)
end
