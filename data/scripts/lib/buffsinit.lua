-- The mod is using this file to load configs

local Azimuth = include("azimuthlib-basic")

local ConfigOptions
if onClient() then
    ConfigOptions = {
      _version = { default = "0.3", comment = "Config version. Don't touch." },
      ConsoleLogLevel = { default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug." },
      FileLogLevel = { default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug." },
      HidePlayerIconsOverlay = { default = false, comment = "If true, the mod will not render player buffs icons in the bottom left corner of a screen." },
      HideShipIconsOverlay = { default = false, comment = "If true, the mod will not render ship buffs icons in the bottom right corner of a screen." }
    }
else -- onServer
    ConfigOptions = {
      _version = {default = "0.3", comment = "Config version. Don't touch."},
      ConsoleLogLevel = { default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug." },
      FileLogLevel = { default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug." },
      UpdateInterval = { default = 2, min = 0.1, comment = "How precise buffs decay is for player-owned ships (smaller = more precise)." },
      NPCUpdateInterval = { default = 3, min = 0.1, comment = "How precise buffs decay is for AI ships (smaller = more precise)." }
    }
end
local Config, isModified = Azimuth.loadConfig("Buffs", ConfigOptions)
-- update config
if Config._version == "0.1" then
    isModified = true
    Config._version = "0.3"
    Config.ConsoleLogLevel = Config.LogLevel or 2
    Config.FileLogLevel = Config.LogLevel or 2
    Config.LogLevel = nil
end
if isModified then
    Azimuth.saveConfig("Buffs", Config, ConfigOptions)
end
local Log = Azimuth.logs("Buffs", Config.ConsoleLogLevel, Config.FileLogLevel)

return {Azimuth, Config, Log, ConfigOptions}