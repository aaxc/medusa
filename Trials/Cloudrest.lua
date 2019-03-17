Medusa = Medusa or {}

Medusa.Cloudrest = {
    name        = "MedusaCloudrestZMaja",
    version     = "1.2.0",
    combatStart = 0,
    debugData = {},

    -- CR Settings
    settings = {
        -- Color settings
        Color = {
            Portal = { r = 26, g = 35, b = 126 },
            BigPortal = {
                main    = { r = 40, g = 53, b = 147 },
                lines   = { r = 95, g = 95, b = 196 },
                explode = { r = 255, g = 95, b = 82 },
            },
            Kite = { r = 74, g = 20, b = 140 },
        },

        -- Combat start events
        General = {
            firstEvent = 20, -- Orbs or fire
            secondEvent = 23, -- Orbs or fire
        },

        -- Portals
        Portal = {
            name    = "PortalUpdate",
            bigName = "BigPortalUpdate",

            abilityId = 103946, -- Shadow Realm Cast
            closeId   = 104792, -- PC Win Shadow Realm

            orbDropped   = 103980, -- Grant Malevolent Core
            orbDelivered = 104047, -- Shadow Piercer Exit

            playerEnterId = { a = 108045, b = 104620 }, -- Shadow World
            playerExitId  = 105218, -- PC Exit SRealm

            foundOrbs       = 0,
            deliveredOrbs   = 0,
            currentGroup    = 1,
            firstAppearance = 55,
            nextAppearances = 45,
            started         = 0,
            totalTime       = 75,
        },

        -- Kiting
        Kite = {
            name      = "KiteUpdate",
            started   = 0,
            abilityId = 105239, -- Crushing Darkness Cas
            timer     = 25,
            duration  = 10,

            kiteAppearance = 80,
        },
    }
}

--[[ Abilities data --]]
-- PC Exit SRealm
Medusa.Cloudrest.playerEnter = {}
Medusa.Cloudrest.playerEnter[108045] = true
Medusa.Cloudrest.playerEnter[104620] = true

-- PC Exit SRealm
Medusa.Cloudrest.playerExit = {}
Medusa.Cloudrest.playerExit[105218] = true

-- Shadow Realm Cast
Medusa.Cloudrest.PortalOpen = {}
Medusa.Cloudrest.PortalOpen[103946] = true

-- PC Win Shadow Realm
Medusa.Cloudrest.PortalClose = {}
Medusa.Cloudrest.PortalClose[104792] = true

-- Grant Malevolent Core
Medusa.Cloudrest.OrbDropped = {}
Medusa.Cloudrest.OrbDropped[103980] = true

-- Shadow Piercer Exit
Medusa.Cloudrest.OrbDelivered = {}
Medusa.Cloudrest.OrbDelivered[104047] = true

-- Crushing Darkness Cas
Medusa.Cloudrest.Kite = {}
Medusa.Cloudrest.Kite[105239] = true


--- MAJOR: Debug data for checking IDs ---
Medusa.Cloudrest.debugDataName = "ORBS KILL"
Medusa.Cloudrest.debugData2 = {}
--- MAJOR: Debug data for checking IDs ---

-------------------------------------------------------------------------------------------------
--  Entry point  --
-------------------------------------------------------------------------------------------------
function Medusa.InitCloudrest()
    Medusa.Cloudrest.combatStart = tonumber(GetTimeStamp())
    EVENT_MANAGER:RegisterForEvent(Medusa.Cloudrest.name, EVENT_COMBAT_EVENT, Medusa.CloudrestCombatCallbacks)
    -- Active combat callbacks

    -- @TODO: Check if mini is killed, if so, adjust timers

    -- @TODO: Check if inside ZMajas room
    -- @TODO: Check if ZMaja is active

    KiteWindow:SetHidden(false)
    EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 100, Medusa.CloudrestShowInitialPortal)

    -- @TODO: Start with first sphere appearance, add "SOON", when over, reset, when killed

    -- @TODO: First event starts in 20 seconds, second 23 (Fire or Orb)

    -- @TODO: Show fire bar with timer and name, when up
end

-------------------------------------------------------------------------------------------------
--  Cloudrest combat callbacks  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestCombatCallbacks(_, result, isError, aName, aGraphic, aActionSlotType, sName, sType, tName, tType, hitValue, pType, dType, log, sUnitId, tUnitId, abilityId)
    -- Pre-set variables
    local current = tonumber(GetTimeStamp())

    --[[ Switch skills ]]--
    -- Crushing Darkness (Kite)
    if abilityId == Medusa.Cloudrest.settings.Kite.abilityId then
        if Medusa.Cloudrest.settings.Kite.started < 1 then
            Medusa.Cloudrest.settings.Kite.started = current
            EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Kite.name, 100, Medusa.CloudrestShowKite)
        end
    -- Portal spawn (Ongoing timers)
    elseif abilityId == Medusa.Cloudrest.settings.Portal.abilityId then
        Medusa.Cloudrest.settings.Portal.foundOrbs     = 0
        Medusa.Cloudrest.settings.Portal.deliveredOrbs = 0
        Medusa.Cloudrest.settings.Portal.started = current
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 100, Medusa.CloudrestShowOngoingPortal)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName, 100, Medusa.CloudrestShowOngoingBigPortal)
    -- Portal close event
    elseif abilityId == Medusa.Cloudrest.settings.Portal.closeId then
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName)
        -- Swap group names
        if Medusa.Cloudrest.settings.Portal.currentGroup == 1 then
            Medusa.Cloudrest.settings.Portal.currentGroup = 2
        else
            Medusa.Cloudrest.settings.Portal.currentGroup = 1
        end

        Medusa.Cloudrest.settings.Portal.started = current
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 100, Medusa.CloudrestShowAdditioanlPortal)
    -- Show on player portal entrance
    elseif abilityId == Medusa.Cloudrest.settings.Portal.playerEnterId.a or
           abilityId == Medusa.Cloudrest.settings.Portal.playerEnterId.b then
        if (tType == COMBAT_UNIT_TYPE_PLAYER) then
            BigPortalWindow:SetHidden(false)
        end
    -- Hide on player portal exit
    elseif abilityId == Medusa.Cloudrest.settings.Portal.playerExitId then
        if (tType == COMBAT_UNIT_TYPE_PLAYER) then
            BigPortalWindow:SetHidden(true)
        end
    -- Add Orb dropped counter
    elseif abilityId == Medusa.Cloudrest.settings.Portal.orbDropped then
        Medusa.Cloudrest.settings.Portal.foundOrbs = Medusa.Cloudrest.settings.Portal.foundOrbs + 1
        PlaySound(SOUNDS.DUEL_START)
    -- Add Orb delivered counter
    elseif abilityId == Medusa.Cloudrest.settings.Portal.orbDelivered and result == 2250 then
        Medusa.Cloudrest.settings.Portal.deliveredOrbs = Medusa.Cloudrest.settings.Portal.deliveredOrbs + 1
    end

    --- MAJOR: ORB TEST DEBUG DATA ---
    if Medusa.Cloudrest.debugData2[abilityId] then
        d(Medusa.Cloudrest.debugDataName .. GetAbilityName(abilityId) .. ':' .. abilityId .. "result: " .. result)
    end
    --- MAJOR: ORB TEST DEBUG DATA ---

    -- Main debug output data. Gathers abilities, counts them and outputs once a second
    if Medusa.debug == true then
        local timestamps = tonumber(GetTimeStamp())
        if hitValue < 10 then
            if Medusa.Cloudrest.debugData[abilityId] then
                Medusa.Cloudrest.debugData[abilityId] = Medusa.Cloudrest.debugData[abilityId] + 1
            else
                Medusa.Cloudrest.debugData[abilityId] = 1
            end

            if timestamps ~= Medusa.debugTime then
                for key,value in pairs(Medusa.Cloudrest.debugData) do
                    local name = GetAbilityName(key)
                    Medusa.debugInfo = Medusa.debugInfo .. " - " .. value .. "x" .. name .. "(" .. key .. ")"
                end
                Medusa.Cloudrest.debugData = {}
                d(Medusa.debugTime .. ": " .. Medusa.debugInfo)
                Medusa.debugTime = timestamps
                Medusa.debugInfo = ""
            end
        end
    end
end

-------------------------------------------------------------------------------------------------
--  Show initial portal messages --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowInitialPortal()
    local current = tonumber(GetTimeStamp())
    local endtime = Medusa.Cloudrest.combatStart + Medusa.Cloudrest.settings.Portal.firstAppearance
    local remaining = endtime - current
    local remainString = Medusa.SecondsToMinutes(remaining)
    local currentGroup = Medusa.Cloudrest.settings.Portal.currentGroup

    -- Activate bar
    local k = Medusa.Cloudrest.settings.Color.Portal
    PortalWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
    PortalWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Portal.firstAppearance)
    PortalWindowStatusBar:SetValue(remaining)
    PortalWindowLabel:SetText("Next portal group " .. currentGroup .. " in")
    PortalWindowLabelTime:SetText(remainString)
    PortalWindow:SetHidden(false)

    -- Exit and stop, when timer runs out
    if remaining < 1 then
        PortalWindowStatusBar:SetMinMax(0, 1)
        PortalWindowStatusBar:SetValue(1)
        PortalWindowLabel:SetText("Portal soon")
        PortalWindowLabelTime:SetText("")
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)

        -- Swap groups at end
        if Medusa.Cloudrest.settings.Portal.currentGroup == 1 then
            Medusa.Cloudrest.settings.Portal.currentGroup = 2
        else
            Medusa.Cloudrest.settings.Portal.currentGroup = 1
        end
    end
end

-------------------------------------------------------------------------------------------------
--  Show ongoing portal messages --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowOngoingPortal()
    local current = tonumber(GetTimeStamp())

    local endtime = Medusa.Cloudrest.settings.Portal.started + Medusa.Cloudrest.settings.Portal.totalTime
    local remaining = endtime - current
    local remainString = Medusa.SecondsToMinutes(remaining)

    -- Sync with regular bar
    local k = Medusa.Cloudrest.settings.Color.BigPortal.main
    PortalWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
    PortalWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Portal.totalTime)
    PortalWindowStatusBar:SetValue(remaining)
    PortalWindowLabel:SetText("Portal in progress")
    PortalWindowLabelTime:SetText(remainString)
    PortalWindow:SetHidden(false)

    -- Exit and stop, when timer runs out
    if remaining < 1 then
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        BigPortalWindow:SetHidden(true)
    end
end

-------------------------------------------------------------------------------------------------
--  Show ongoing big portal messages --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowOngoingBigPortal()
    local current = tonumber(GetTimeStamp())

    local endtime = Medusa.Cloudrest.settings.Portal.started + Medusa.Cloudrest.settings.Portal.totalTime
    local remaining = endtime - current
    local remainString = Medusa.SecondsToMinutes(remaining)

    -- Activate bar
    local k = Medusa.Cloudrest.settings.Color.BigPortal.main
    BigPortalWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
    BigPortalWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Portal.totalTime)
    BigPortalWindowStatusBar:SetValue(remaining)
    BigPortalWindowLabelTime:SetText(remainString)

    local orbs = Medusa.Cloudrest.settings.Portal.foundOrbs .. "/" .. Medusa.Cloudrest.settings.Portal.deliveredOrbs
    BigPortalWindowOrbs:SetText(orbs)

    BigPortalWindowLabelTime:SetText(remainString)
    BigPortalWindowLabelTime:SetText(remainString)

    -- Exit and stop, when timer runs out
    if remaining < 1 then
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName)
        BigPortalWindow:SetHidden(true)
    end
end

-------------------------------------------------------------------------------------------------
--  Show additional portal messages --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowAdditioanlPortal()
    local current = tonumber(GetTimeStamp())
    local endtime = Medusa.Cloudrest.settings.Portal.started + Medusa.Cloudrest.settings.Portal.nextAppearances
    local remaining = endtime - current
    local remainString = Medusa.SecondsToMinutes(remaining)
    local currentGroup = Medusa.Cloudrest.settings.Portal.currentGroup

    -- Activate bar
    local k = Medusa.Cloudrest.settings.Color.Portal
    PortalWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
    PortalWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Portal.nextAppearances)
    PortalWindowStatusBar:SetValue(remaining)
    PortalWindowLabel:SetText("Next portal group " .. currentGroup .. " in") -- TODO: Group changing seems broken :/
    PortalWindowLabelTime:SetText(remainString)
    PortalWindow:SetHidden(false)

    -- Exit and stop, when timer runs out
    if remaining < 1 then
        PortalWindowStatusBar:SetMinMax(0, 1)
        PortalWindowStatusBar:SetValue(1)
        PortalWindowLabel:SetText("Portal soon")
        PortalWindowLabelTime:SetText("")
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
    end
end

-------------------------------------------------------------------------------------------------
--  Show portal messages --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowKite()
    local current = tonumber(GetTimeStamp())
    local endtime = Medusa.Cloudrest.settings.Kite.started + Medusa.Cloudrest.settings.Kite.timer
    local remaining = endtime - current

    local k = Medusa.Cloudrest.settings.Color.Kite
    local kiteTime = Medusa.Cloudrest.settings.Kite.started - current + Medusa.Cloudrest.settings.Kite.duration
    if kiteTime > 0 then
        local remainString = Medusa.SecondsToMinutes(kiteTime)
        KiteWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Kite.duration)
        KiteWindowStatusBar:SetValue(kiteTime)
        KiteWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
        KiteWindowLabel:SetText("Crushing Darkness ongoing")
        KiteWindowLabelTime:SetText(remainString)
        KiteWindow:SetHidden(false)
    else
        local remainString = Medusa.SecondsToMinutes(remaining)
        KiteWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Kite.timer)
        KiteWindowStatusBar:SetValue(remaining)
        KiteWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
        KiteWindowLabel:SetText("Next Crushing Darkness in")
        KiteWindowLabelTime:SetText(remainString)
        KiteWindow:SetHidden(false)
    end

    -- Exit and stop, when timer runs out
    if remaining < 1 then
        Medusa.Cloudrest.settings.Kite.started = 0
        KiteWindowStatusBar:SetMinMax(0, 1)
        KiteWindowStatusBar:SetValue(1)
        KiteWindowLabel:SetText("Crushing Darkness soon")
        KiteWindowLabelTime:SetText("")
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Kite.name)
    end
end

-------------------------------------------------------------------------------------------------
--  Save location  --
-------------------------------------------------------------------------------------------------
function Medusa.PortalWindowSaveLoc()
    Medusa.savedVariables.PortalWindowOffsetX = PortalWindow:GetLeft()
    Medusa.savedVariables.PortalWindowOffsetY = PortalWindow:GetTop()
    Medusa.savedVariables.PortalWindowLocation = TOPLEFT
end
function Medusa.BigPortalWindowSaveLoc()
    Medusa.savedVariables.BigPortalWindowOffsetX = BigPortalWindow:GetLeft()
    Medusa.savedVariables.BigPortalWindowOffsetY = BigPortalWindow:GetTop()
    Medusa.savedVariables.BigPortalWindowLocation = TOPLEFT
end
function Medusa.KiteWindowSaveLoc()
    Medusa.savedVariables.KiteWindowOffsetX = KiteWindow:GetLeft()
    Medusa.savedVariables.KiteWindowOffsetY = KiteWindow:GetTop()
    Medusa.savedVariables.KiteWindowLocation = TOPLEFT
end

-------------------------------------------------------------------------------------------------
--  Show/hide bars  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowBars(show)
    if show == true then
        PortalWindow:SetHidden(false)
        BigPortalWindow:SetHidden(false)
        KiteWindow:SetHidden(false)
    else
        PortalWindow:SetHidden(true)
        BigPortalWindow:SetHidden(true)
        KiteWindow:SetHidden(true)
    end
end

-------------------------------------------------------------------------------------------------
--  Hides all windows  --
-------------------------------------------------------------------------------------------------
function Medusa.Cloudrest.Reset()
    Medusa.Cloudrest.settings.Portal.currentGroup  = 1
    Medusa.Cloudrest.settings.Portal.foundOrbs     = 0
    Medusa.Cloudrest.settings.Portal.deliveredOrbs = 0
    Medusa.Cloudrest.settings.Kite.started = 0
    PortalWindowLabel:SetText("Portal soon")
    PortalWindowStatusBar:SetMinMax(0, 1)
    PortalWindowStatusBar:SetValue(1)
    PortalWindowLabelTime:SetText("")
    PortalWindow:SetHidden(true)
    BigPortalWindow:SetHidden(true)
    KiteWindow:SetHidden(true)
    KiteWindowLabel:SetText("First kite at 80%")
    KiteWindowStatusBar:SetMinMax(0, 1)
    KiteWindowStatusBar:SetValue(0)
    KiteWindowLabelTime:SetText("")
end