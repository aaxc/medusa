Medusa = {
    -- Main info
    name = "Medusa",
    version = "1.1.4",
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
    }
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
    end

    -- Check location and make action
    if inCombat then
        -- Entering combat
        if Medusa.location == "Cloudrest" then
            Medusa.InitCloudrest()
        else
            Medusa.StopAllCombatEvents() -- @TODO: Can use one method, but only check, if combat has ended for more than 2 seconds or so
        end
    else
        -- Exiting combat
        if Medusa.location == "Cloudrest" then
            Medusa.StopCombatEvents()
            Medusa.Cloudrest.combatStart = 0
        else
            Medusa.StopAllCombatEvents()
        end
    end
end

-------------------------------------------------------------------------------------------------
--  Stop specific events, when combat ends  --
-------------------------------------------------------------------------------------------------
function Medusa.StopCombatEvents()
    -- Stop events
    EVENT_MANAGER:UnregisterForEvent(Medusa.Cloudrest.name)
end

-------------------------------------------------------------------------------------------------
--  Stop all events, when combat ends  --
-------------------------------------------------------------------------------------------------
function Medusa.StopAllCombatEvents()
    -- Stop portal timers
    PortalWindow:SetHidden(true)
    KiteWindow:SetHidden(true)

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
    local i, mins = 0
    local msg = "Break"
    for k in string.gmatch(extra, "%S+") do
        i = i + 1
        if i == 1 then
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
--  Helper method to determine if item is in given table/array  --
-------------------------------------------------------------------------------------------------
function Medusa.inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

-------------------------------------------------------------------------------------------------
--  Command requests Methods  --
-------------------------------------------------------------------------------------------------
-- General events and commands
-- @TODO: make general commade, like /medusa or /md with additions
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_PLAYER_COMBAT_STATE, Medusa.OnPlayerCombatState)
EVENT_MANAGER:RegisterForEvent(Medusa.name, EVENT_ADD_ON_LOADED, Medusa.OnAddOnLoaded)
SLASH_COMMANDS["/mdbreak"] = function(extra)
    Medusa.BreakCommand(extra)
end
SLASH_COMMANDS["/mddebug"] = function(extra)
    Medusa.DebugCommand(extra)
end