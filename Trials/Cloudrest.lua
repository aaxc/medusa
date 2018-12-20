Medusa = Medusa or {}

Medusa.Cloudrest = {
    version = "1.0.5",
    combatStart = 0,
    name = "MedusaCloudrestZMaja",
    targetId = 0,

    -- CR Settings
    settings = {
        -- Color settings
        Color = {
            Portal = { r = 26, g = 35, b = 126 },
            BigPortal = {
                main = { r = 40, g = 53, b = 147 },
                lines = { r = 95, g = 95, b = 196 },
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
            name = "PortalUpdate",
            bigName = "BigPortalUpdate",

            spiderSpawn = 104216, -- @TODO WRONG
            closeId = {
                a = 104792, -- PC Win Shadow Realm
                b = 109017, -- Shift Shadow Stop
            },
            orbDelivered = 104047, -- Shadow Piercer Exit
            abilityId = 103946, -- Shadow Realm Cast
            playerEnterId = { a = 108045, b = 104620 }, -- Shadow World
            playerExitId = 105218, -- PC Exit SRealm

            currentGroup = 1,
            firstAppearance = 55,
            nextAppearances = 45,
            started = 0,
            totalTime = 75,
        },

        -- Kiting
        Kite = {
            name = "KiteUpdate",
            started = 0,
            abilityId = 105239, -- Crushing Darkness Cas
            timer = 25,
            duration = 10,

            kiteAppearance = 80,
        },

        -- Spheres
        Spheres = {
            name = "SpheresUpdate",
            abilityId = 105291, -- SUM Shadow Beads
            firstAppearance = 20,
            nextAppearances = 35,
        }
    }
}

-------------------------------------------------------------------------------------------------
--  Entry point  --
-------------------------------------------------------------------------------------------------
function Medusa.InitCloudrest()
    Medusa.Cloudrest.combatStart = tonumber(GetTimeStamp())
    EVENT_MANAGER:RegisterForEvent(Medusa.Cloudrest.name, EVENT_COMBAT_EVENT, Medusa.CloudrestCombatCallbacks)
    -- Active combat callbacks

    -- @TODO: Check if mini is killed, if so, return false, as this is only for +3

    -- @TODO: Check if inside ZMajas room
    -- @TODO: Check if ZMaja is active

    -- 1: Start with portal counter, add GROUP 1
    -- 2: Add "SOON" once over
    -- @TODO 3: Add "IN PROGRESS" while its going and show timer, till Z'Maja comes up
    -- @TODO 4: Reset when portal closed and add NEXT group to message
    KiteWindow:SetHidden(false)
    EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowInitialPortal)

    -- @TODO: Start with first sphere appearance, add "SOON", when over, reset, when killed
    -- @TODO: Add block notice, when sphere dies

    -- @TODO: First event starts in 20 seconds, second 23 (Fire or Orb)

    -- @TODO: Show fire bar with timer and name, when up
    -- @TODO: Show frost with timer, when up
end

-------------------------------------------------------------------------------------------------
--  Cloudrest combat callbacks  --
-------------------------------------------------------------------------------------------------
function Medusa.CloudrestCombatCallbacks(_, result, isError, aName, aGraphic, aActionSlotType, sName, sType, tName, tType, hitValue, pType, dType, log, sUnitId, tUnitId, abilityId)
    -- Pre-set variables
    local current = tonumber(GetTimeStamp())
    Medusa.Cloudrest.targetId = tUnitId

    --[[ Switch skills ]]--
    -- Crushing Darkness (Kite)
    if abilityId == Medusa.Cloudrest.settings.Kite.abilityId then
        if Medusa.Cloudrest.settings.Kite.started < 1 then
            Medusa.Cloudrest.settings.Kite.started = current
            EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Kite.name, 1000, Medusa.CloudrestShowKite)
        end
    -- Portal spawn (Ongoing timers)
    elseif abilityId == Medusa.Cloudrest.settings.Portal.abilityId and pType < 1 then
        Medusa.Cloudrest.settings.Portal.started = current
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowOngoingPortal)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName, 1000, Medusa.CloudrestShowOngoingBigPortal)
    -- Additional portal spawn times
    elseif Medusa.inTable(Medusa.Cloudrest.settings.Portal.closeId, abilityId) or abilityId == Medusa.Cloudrest.settings.Portal.spiderSpawn
    then
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.name)
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Cloudrest.settings.Portal.bigName)
        BigPortalWindow:SetHidden(true)
        -- Swap group names
        if Medusa.Cloudrest.settings.Portal.currentGroup == 1 then
            Medusa.Cloudrest.settings.Portal.currentGroup = 2
        else
            Medusa.Cloudrest.settings.Portal.currentGroup = 1
        end
        Medusa.Cloudrest.settings.Portal.started = current
        EVENT_MANAGER:RegisterForUpdate(Medusa.Cloudrest.settings.Portal.name, 1000, Medusa.CloudrestShowAdditioanlPortal)
    -- Show on player portal entrance
    elseif Medusa.inTable(Medusa.Cloudrest.settings.Portal.playerEnterId, abilityId) then
        if (tType == COMBAT_UNIT_TYPE_PLAYER) then
            BigPortalWindow:SetHidden(false)
        end
    -- Hide on player portal exit
    elseif abilityId == Medusa.Cloudrest.settings.Portal.playerExitId then
        if (tType == COMBAT_UNIT_TYPE_PLAYER) then
            BigPortalWindow:SetHidden(true)
        end
    end

    -- Main debug output data
    if Medusa.debug == true then
        local timestamps = tonumber(GetTimeStamp())
        if hitValue < 10 then
            local abilityName = abilityId .. "(" .. GetAbilityName(abilityId) .. ")"
            Medusa.debugInfo = Medusa.debugInfo .. ", " .. abilityName
            if timestamps ~= Medusa.debugTime then
                d(Medusa.debugTime .. ": " .. Medusa.debugInfo)
                Medusa.debugTime = timestamps
                Medusa.debugInfo = ""
            end
        end
    end

    --d("Ability Name: "  ..  aName ..
    --", Ability Id: " .. abilityId ..
    --", Target Name: " .. tName ..
    --", Target Type: " .. tType ..
    --", Target Unit ID: " .. tUnitId ..
    --", Attacker Unit Id: " .. sUnitId ..
    --", Attacker Name: " .. sName ..
    --", Attacker Type: " .. sType ..
    --", Hit Value: " .. hitValue ..
    --", pType: " .. pType ..
    --", dType: " .. dType)

    --d("result")
    --d(result)
    --d("isError")
    --d(isError)
    --d("aName")
    --d(aName)
    --d("aGraphic")
    --d(aGraphic)
    --d("aActionSlotType")
    --d(aActionSlotType)
    --d("sName")
    --d(sName)
    --d("sType")
    --d(sType)
    --d("tName")
    --d(tName)
    --d("tType")
    --d(tType)
    --d("hitValue")
    --d(hitValue)
    --d("pType")
    --d(pType)
    --d("dType")
    --d(dType)
    --d("log")
    --d(log)
    --d("sUnitId")
    --d(sUnitId)
    --d("tUnitId")
    --d(tUnitId)
    --d("abilityId")
    --d(abilityId)
    --d('----')
    --local test = {
    --    name = "Minor Wound",
    --    abilityId = 10601,
    --    sUnitId = 48490,
    --    sName = "Skeletal Healer",
    --}
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
    k = Medusa.Cloudrest.settings.Color.Portal
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
    k = Medusa.Cloudrest.settings.Color.BigPortal.main
    BigPortalWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
    BigPortalWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Portal.totalTime)
    BigPortalWindowStatusBar:SetValue(remaining)
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

    --d("Current:" .. current .. ", Started:" .. Medusa.Cloudrest.settings.Portal.started .. ", Endtime:" .. endtime .. ", NextAppearance:" .. Medusa.Cloudrest.settings.Portal.nextAppearances .. ", Remaining:" .. remaining)

    -- Activate bar
    k = Medusa.Cloudrest.settings.Color.Portal
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

    k = Medusa.Cloudrest.settings.Color.Kite
    local kiteTime = Medusa.Cloudrest.settings.Kite.started - current + Medusa.Cloudrest.settings.Kite.duration
    if kiteTime > 0 then
        local remainString = Medusa.SecondsToMinutes(kiteTime)
        KiteWindowStatusBar:SetMinMax(0, Medusa.Cloudrest.settings.Kite.duration)
        KiteWindowStatusBar:SetValue(kiteTime)
        KiteWindowStatusBar:SetColor(k.r / 255, k.g / 255, k.b / 255)
        KiteWindowLabel:SetText("Crushing Darkness on you. Kite!")
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