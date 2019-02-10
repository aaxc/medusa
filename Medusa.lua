Medusa = {
    -- Main info
    name = "Medusa",
    version = "1.1.7",
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
    },

    -- Combat exit timer
    exitCombat = 0
}

-------------------------------------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------------------------------------
function Medusa.OnAddOnLoaded(event, addonName)
    if addonName ~= Medusa.name then
        return
    end

    Medusa:Initialize(0, "")
end

-------------------------------------------------------------------------------------------------
--  OnPlayerCombatState  --
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
--  Adds combat queue for 5s after exit
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
--  Stop all events, when combat ends  --
-------------------------------------------------------------------------------------------------
function Medusa.StopAllCombatEvents()
    -- Stop portal timers
    Medusa.Cloudrest.Reset()
--    PortalWindow:SetHidden(true)
--    BigPortalWindow:SetHidden(true)
--    KiteWindow:SetHidden(true)

    -- Stop events
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName)
    EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Kite.name)
    EVENT_MANAGER:UnregisterForEvent(Medusa.Cloudrest.name)
end


-------------------------------------------------------------------------------------------------
--  Initialize Medusa --
-------------------------------------------------------------------------------------------------
function Medusa:Initialize()

    -- @TODO Register all states when inside CLOUDREST, else do nothing

    -- Set combat state
    Medusa.inCombat = IsUnitInCombat("player")

    -- Load saved savedVariables
    Medusa.savedVariables = ZO_SavedVars:NewAccountWide("MedusaVars", Medusa.variableVersion, nil, Medusa.Default)

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
--  Show/hide bars for debug options  --
-------------------------------------------------------------------------------------------------
function Medusa.DebugCommand(extra)
    -- Get parameter data
    local i = 0
    for k in string.gmatch(extra, "%S+") do
        i = i + 1
        if i == 2 then
            -- check if stop command given
            if k == "show" then
                Medusa.debug = true,
                Medusa.BreakShowBars(true)
                Medusa.CloudrestShowBars(true)
            end

            if k == "hide" then
                Medusa.debug = false,
                Medusa.BreakShowBars(false)
                Medusa.CloudrestShowBars(false)
            end
        end
    end
end

-------------------------------------------------------------------------------------------------
--  Manage slash commands --
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
--  Command requests Methods  --
-------------------------------------------------------------------------------------------------
-- General events and commands
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_PLAYER_COMBAT_STATE, Medusa.OnPlayerCombatState)
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_ADD_ON_LOADED, Medusa.OnAddOnLoaded)
SLASH_COMMANDS["/md"] = function(extra)
    Medusa.SlashCommands(extra)
end
