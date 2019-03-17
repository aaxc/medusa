-------------------------------------------------------------------------------------------------
-- Settings --
-------------------------------------------------------------------------------------------------
Lang.Settings_General_Header = "General"
Lang.Settings_General_LockBar = "Locks Bars"
Lang.Settings_General_Trials = "Trials"
Lang.Settings_General_Trials_Description = "Here you can configure different trial settings. What you want or don't want to see and what size bars and colors you want to see."
Lang.Settings_General_Trials_Cloudrest_Kite = "Kite - Crushing Darkness"
Lang.Settings_General_Trials_Cloudrest_Kite_Show = "Show Kite Bar"
Lang.Settings_General_Trials_Cloudrest_Kite_Width = "Adjust Width"
Lang.Settings_General_Trials_Cloudrest_Kite_Height = "Adjust Height"

-------------------------------------------------------------------------------------------------
-- Create String IDs --
-------------------------------------------------------------------------------------------------
for k, v in pairs(Lang) do
    local stringId = "MEDUSALANG_" .. stringId.upper(k)
    ZO_CreateStringId(stringId, v)
end
