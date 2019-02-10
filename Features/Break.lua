Medusa = Medusa or {}

Medusa.Break = {
    name = "Break Bar",
    version = "1.1.1",
    author = "@Aaxc",

    -- Timestamp variables
    commandName = "Bartime",
    Bartime = {
        total = 0,
        endTime = 0,
        message = "",
        endFlash = 1,
        ColourGradient = {
            c1 = { 139, 195, 74 },
            c2 = { 160, 198, 72 },
            c3 = { 183, 202, 70 },
            c4 = { 206, 203, 68 },
            c5 = { 210, 184, 65 },
            c6 = { 213, 163, 63 },
            c7 = { 217, 139, 61 },
            c8 = { 221, 114, 58 },
            c9 = { 225, 86, 55 },
            c10 = { 229, 56, 52 },
        }
    },

    UsageManual = {
        wrongMessage = "Check /mdbreak help",
        inProgressMessage = "A timer is already in progress, please use /mdbreak stop first",
        endingMessage = "Break time is over!",
        helpMessage1 = "Start: /mdbreak {time-in-minutes} {optinal-message}",
        helpMessage2 = "Stop: /mdbreak stop",
        helpMessage3 = "Help: /mdbreak help",
    },
}

-------------------------------------------------------------------------------------------------
--  Convert seconds to MM:SS format  --
-------------------------------------------------------------------------------------------------
function Medusa.SecondsToMinutes(remaining)
    -- Get minutes
    local mins = math.floor(remaining / 60)
    if mins < 0 then
        mins = "0"
    else
        mins = tostring(mins)
    end

    -- Get seconds
    local secs = remaining - (mins * 60)
    if (secs < 10) then
        secs = "0" .. tostring(secs)
    else
        secs = tostring(secs)
    end

    return mins .. ":" .. secs
end

-------------------------------------------------------------------------------------------------
--  Other Functions  --
-------------------------------------------------------------------------------------------------
function Medusa.UpdateBar()
    local current = tonumber(GetTimeStamp())
    local remaining = Medusa.Break.Bartime.endTime - current

    local LGS = LibStub("LibGroupSocket")
    local resourceHandler = LGS:GetHandler(LGS.MESSAGE_TYPE_RESOURCES)

    -- Create time string
    local remainString = Medusa.SecondsToMinutes(remaining)

    -- Activate bar
    MedusaWindowStatusBar:SetMinMax(0, Medusa.Break.Bartime.total)
    MedusaWindowStatusBar:SetValue(remaining)
    MedusaWindowLabel:SetText(Medusa.Break.Bartime.message)
    MedusaWindowLabelTime:SetText(remainString)
    MedusaWindow:SetHidden(false)

    -- Add extra color changes
    local ratio = remaining / Medusa.Break.Bartime.total
    local k = Medusa.Break.Bartime.ColourGradient
    if ratio > 0.9 then
        MedusaWindowStatusBar:SetColor(k.c1[1] / 255, k.c1[2] / 255, k.c1[3] / 255)
    elseif ratio > 0.8 then
        MedusaWindowStatusBar:SetColor(k.c2[1] / 255, k.c2[2] / 255, k.c2[3] / 255)
    elseif ratio > 0.7 then
        MedusaWindowStatusBar:SetColor(k.c3[1] / 255, k.c3[2] / 255, k.c3[3] / 255)
    elseif ratio > 0.6 then
        MedusaWindowStatusBar:SetColor(k.c4[1] / 255, k.c4[2] / 255, k.c4[3] / 255)
    elseif ratio > 0.5 then
        MedusaWindowStatusBar:SetColor(k.c5[1] / 255, k.c5[2] / 255, k.c5[3] / 255)
    elseif ratio > 0.4 then
        MedusaWindowStatusBar:SetColor(k.c6[1] / 255, k.c6[2] / 255, k.c6[3] / 255)
    elseif ratio > 0.3 then
        MedusaWindowStatusBar:SetColor(k.c7[1] / 255, k.c7[2] / 255, k.c7[3] / 255)
    elseif ratio > 0.2 then
        MedusaWindowStatusBar:SetColor(k.c8[1] / 255, k.c8[2] / 255, k.c8[3] / 255)
    elseif ratio > 0.1 then
        MedusaWindowStatusBar:SetColor(k.c9[1] / 255, k.c9[2] / 255, k.c9[3] / 255)
    else
        MedusaWindowStatusBar:SetColor(k.c10[1] / 255, k.c10[2] / 255, k.c10[3] / 255)
    end

    -- Exit and stop, when timer runs out
    if remaining >= -5 and remaining < 1 then
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Break.commandName)
        EVENT_MANAGER:RegisterForUpdate(Medusa.Break.commandName, 300, Medusa.UpdateBar)
        MedusaWindowLabel:SetText(Medusa.Break.UsageManual.endingMessage)
        MedusaWindowLabelTime:SetText("")
        MedusaWindowStatusBar:SetValue(Medusa.Break.Bartime.total)
        if Medusa.Break.Bartime.endFlash == 1 then
            Medusa.Break.Bartime.endFlash = 2
            MedusaWindowStatusBar:SetColor(k.c10[1] / 255, k.c10[2] / 255, k.c10[3] / 255)
        else
            Medusa.Break.Bartime.endFlash = 1
            MedusaWindowStatusBar:SetColor(k.c4[1] / 255, k.c4[2] / 255, k.c4[3] / 255)
        end
    elseif remaining < -5 then
        MedusaWindow:SetHidden(true)
        Medusa.Break.Bartime.total = 0
        EVENT_MANAGER:UnregisterForUpdate(Medusa.Break.commandName)
    end
end

-------------------------------------------------------------------------------------------------
--  Save location  --
-------------------------------------------------------------------------------------------------
function Medusa.MedusaWindowSaveLoc()
    Medusa.savedVariables.MedusaWindowOffsetX = MedusaWindow:GetLeft()
    Medusa.savedVariables.MedusaWindowOffsetY = MedusaWindow:GetTop()
    Medusa.savedVariables.MedusaWindowLocation = TOPLEFT
end

-------------------------------------------------------------------------------------------------
--  Initialize command request  --
--
--  /mdbreak {time-in-minutes} {optional-message}
--  /mdbreak stop
--  /mdbreak help
--
--  Example:
--      /mdbreak 5
--      /mdbreak 10 Half-trial break
--
-------------------------------------------------------------------------------------------------
function Medusa.BreakCommand(extra)
    -- Get parameter data
    local i, mins = 0
    local msg = "Break"
    for k in string.gmatch(extra, "%S+") do
        i = i + 1
        if i == 1 then
        elseif i == 2 then
            -- check if stop command given
            if k == "stop" then
                MedusaWindow:SetHidden(true)
                Medusa.Break.Bartime.total = 0
                EVENT_MANAGER:UnregisterForUpdate(Medusa.Break.commandName)
                return
            end

            if k == "help" then
                d(Medusa.Break.UsageManual.helpMessage1)
                d(Medusa.Break.UsageManual.helpMessage2)
                d(Medusa.Break.UsageManual.helpMessage3)
                return
            end

            mins = tonumber(k)
        else
            -- Reset if third parameter set
            if i == 3 then
                msg = ""
            end
            msg = msg .. k .. " "
        end
    end

    -- Return with debug message, if wrong parameters
    if mins == nil then
        d(Medusa.Break.UsageManual.wrongMessage)
        return
    end

    -- Return stop message, if already in progress
    if Medusa.Break.Bartime.total > 0 then
        d(Medusa.Break.UsageManual.inProgressMessage)
        return
    end

    -- Initialize event and the bar
    EVENT_MANAGER:RegisterForUpdate(Medusa.Break.commandName, 1000, Medusa.UpdateBar)

    Medusa.Break.Bartime.total = mins * 60
    Medusa.Break.Bartime.endTime = tonumber(GetTimeStamp()) + Medusa.Break.Bartime.total
    Medusa.Break.Bartime.message = msg

    -- Call bar object
    Medusa:UpdateBar()
end

-------------------------------------------------------------------------------------------------
--  Show/hide bars  --
-------------------------------------------------------------------------------------------------
function Medusa.BreakShowBars(show)
    if show == true then
        MedusaWindow:SetHidden(false)
    else
        MedusaWindow:SetHidden(true)
    end
end