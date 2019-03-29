Medusa = Medusa or {}

Medusa.Cloudrest = {
    name        = "MedusaCloudrestZMaja",
    version     = "1.2.1",
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

--Medusa.CloudrestData.abilities.portalOrbDelivered
-- @TODO Check difficulty and load necessary settings
Medusa.difficulty = GetCurrentZoneDungeonDifficulty()
local CLOUDREST_VETERAN_3 = 2

--- MAJOR: Debug data for checking IDs ---
Medusa.Cloudrest.debugDataName = "ORBS KILL"
Medusa.Cloudrest.debugData2 = {}
--- MAJOR: Debug data for checking IDs ---

-------------------------------------------------------------------------------------------------
-- Entry point  --
-------------------------------------------------------------------------------------------------
function Medusa.InitCloudrest()
    if Medusa.difficulty == CLOUDREST_VETERAN_3 or Medusa.savedVariables.showVeteran == false then
        if DoesUnitExist('boss1') and GetUnitName('boss1') == Medusa.Language.Settings_Cloudrest_EndBoss1 then
            Medusa.Cloudrest.combatStart = tonumber(GetTimeStamp())
            EVENT_MANAGER:RegisterForEvent(Medusa.Cloudrest.name, EVENT_COMBAT_EVENT, Medusa.CloudrestCombatCallbacks)
            -- Active combat callbacks

            -- @TODO: Check if mini is killed, if so, adjust timers

            -- @TODO: Check if ZMaja is active

            if Medusa.savedVariables.kiteShow then
                KiteWindow:SetHidden(false)
            end
            EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowInitialPortal)

            -- @TODO: Start with first sphere appearance, add "SOON", when over, reset, when killed

            -- @TODO: First event starts in 20 seconds, second 23 (Fire or Orb)

            -- @TODO: Show fire bar with timer and name, when up

            -- @TODO: Show Creeper spawn
        end
    end
end

-------------------------------------------------------------------------------------------------
-- Cloudrest combat callbacks  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestCombatCallbacks(_, result, isError, aName, aGraphic, aActionSlotType, sName, sType, tName, tType, hitValue, pType, dType, log, sUnitId, tUnitId, abilityId)
    -- Pre-set variables
    local current = tonumber(GetTimeStamp())

    --[[ Switch skills ]] --
    -- Crushing Darkness (Kite)
    if abilityId == Medusa.Cloudrest.settings.Kite.abilityId then
        if Medusa.savedVariables.kiteShow then
            if Medusa.Cloudrest.settings.Kite.started < 1 then
                Medusa.Cloudrest.settings.Kite.started = current
                EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Kite.name, 1000, Medusa.CloudrestShowKite)
            end
        end
        -- Portal spawn (Ongoing timers)
    elseif abilityId == Medusa.Cloudrest.settings.Portal.abilityId then
        Medusa.Cloudrest.settings.Portal.foundOrbs     = 0
        Medusa.Cloudrest.settings.Portal.deliveredOrbs = 0
        Medusa.Cloudrest.settings.Portal.started = current
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowOngoingPortal)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName, 1000, Medusa.CloudrestShowOngoingBigPortal)
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
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowAdditioanlPortal)
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
                for key, value in pairs(Medusa.Cloudrest.debugData) do
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
--    PortalWindowLabel:SetText(string.format("Next portal group %s in", currentGroup))
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
-- Save location  --
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
-- Adjust sizes  --
-------------------------------------------------------------------------------------------------
function Medusa.KiteSetBarSize(_width, _height)
    KiteWindow:SetDimensions(_width, _height)
    KiteWindowBackdrop:SetDimensions(_width, _height)
    KiteWindowStatusBar:SetDimensions(_width, _height)
    KiteWindowLabel:SetDimensions(_width, _height)
    KiteWindowLabelTime:SetDimensions(_width, _height)
end

-------------------------------------------------------------------------------------------------
-- Show/hide bars  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestShowBars(_show)
    PortalWindow:SetHidden(not _show)
    BigPortalWindow:SetHidden(not _show)
    KiteWindow:SetHidden(not _show)

    -- Set fully colored for easier color picking
    KiteWindowStatusBar:SetMinMax(0, 1)
    PortalWindowStatusBar:SetMinMax(0, 1)
    if _show == true then
        KiteWindowStatusBar:SetValue(1)
        PortalWindowStatusBar:SetValue(1)
    else
        KiteWindowStatusBar:SetValue(0)
        PortalWindowStatusBar:SetValue(0)
    end
end

-------------------------------------------------------------------------------------------------
-- Lock/unlock bar movement  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestUnLockBars(_show)
    PortalWindow:SetMovable(_show)
    BigPortalWindow:SetMovable(_show)
    KiteWindow:SetMovable(_show)
end


-------------------------------------------------------------------------------------------------
-- Hides all windows  --
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