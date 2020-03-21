--- A helper file for the Buffs mod.
-- module: BuffsHelper
-- author: Rinart73
-- license: MIT
-- release: 0.3

include("utility")

local BuffsHelper = {}

-- MOD HELPERS --
-- Functions and variables (shared code basically) that are mostly intended to be used by the mod itself and not by modders (although I can't tell you what to do)
local isServer = onServer()
if not isServer then

BuffsHelper.SortedBonuses = {
  "RadarReach",
  "HiddenSectorRadarReach",
  "ScannerReach",
  "ScannerMaterialReach",
  "HyperspaceReach",
  "HyperspaceCooldown",
  "HyperspaceRechargeEnergy",
  "ShieldDurability",
  "ShieldRecharge",
  "ShieldTimeUntilRechargeAfterHit",
  "ShieldTimeUntilRechargeAfterDepletion",
  "ShieldImpenetrable",
  "Velocity",
  "Acceleration",
  "GeneratedEnergy",
  "EnergyCapacity",
  "BatteryRecharge",
  "ArbitraryTurrets",
  "UnarmedTurrets",
  "ArmedTurrets",
  "DefenseWeapons",
  "CargoHold",
  "LootCollectionRange",
  "TransporterRange",
  "FighterCargoPickup",
  "PilotsPerFighter",
  "MinersPerTurret",
  "GunnersPerTurret",
  "MechanicsPerTurret",
  "Engineers",
  "Mechanics",
  "Gunners",
  "Miners",
  "Security",
  "Attackers",
  "Sergeants",
  "Lieutenants",
  "Commanders",
  "Generals",
  "Captains",
}
BuffsHelper.BonusNameByIndex = {}
for _, key in ipairs(BuffsHelper.SortedBonuses) do
    BuffsHelper.BonusNameByIndex[StatsBonuses[key]] = key
end
BuffsHelper.BonusesDisplay = {
  RadarReach = {
    name = "Radar Range"%_t,
    func = function(stats) return stats.radarRadius + 14 end
  },
  HiddenSectorRadarReach = {
    name = "Deep Scan Range"%_t,
    value = 0
  },
  ScannerReach = {
    name = "Scanner Range"%_t,
    value = 500 -- 5km?
  },
  ScannerMaterialReach = {
    name = "Material Scanner Range"%_t,
    value = 500 -- 5km?
  },
  HyperspaceReach = {
    name = "Jump Range"%_t,
    func = function(stats) return math.pow(stats.hyperspacePower, 1/3) + 2.5 end
  },
  HyperspaceCooldown = {
    name = "Hyperspace Cooldown"%_t,
    -- unknown formula
  },
  HyperspaceRechargeEnergy = {
    name = "Recharge Energy"%_t.." (".."Hyperdrive"%_t..")",
    -- unknown formula
  },
  ShieldDurability = {
    name = "Shield Durability"%_t,
    stat = "shield"
  },
  ShieldRecharge = {
    name = "Shield Recharge Rate"%_t,
    -- unknown formula
  },
  ShieldTimeUntilRechargeAfterHit = {
    name = "Time Until Recharge"%_t.." (".."Shield"%_t..")",
    value = 30 -- from hints
  },
  ShieldTimeUntilRechargeAfterDepletion = {
    name = "Time Until Recharge (Depletion)"%_t.." (".."Shield"%_t..")",
    value = 30 -- not sure
  },
  ShieldImpenetrable = {
    name = "Impenetrable Shields"%_t,
    value = 0 -- boolean
  },
  Velocity = {
    name = "Velocity"%_t
    -- unknown formula
  },
  Acceleration = {
    name = "Acceleration"%_t,
    -- unknown formula
  },
  GeneratedEnergy = {
    name = "Generated Energy"%_t,
    stat = "energyYield"
  },
  EnergyCapacity = {
    name = "Energy Capacity"%_t,
    stat = "storableEnergy"
  },
  BatteryRecharge = {
    name = "Recharge Rate"%_t,
    func = function(stats) return stats.storableEnergy * 0.05 end
  },
  ArbitraryTurrets = {
    name = "Armed or Unarmed Turret Slots"%_t,
    value = 1
  },
  UnarmedTurrets = {
    name = "Unarmed Turret Slots"%_t,
    value = 1
  },
  ArmedTurrets = {
    name = "Armed Turret Slots"%_t,
    value = 1
  },
  CargoHold = {
    name = "Cargo Hold"%_t,
    stat = "cargoHold"
  },
  LootCollectionRange = {
    name = "Loot Collection Range"%_t,
    value = 100 -- 1km?
  },
  TransporterRange = {
    name = "Docking Distance"%_t,
    value = 0
  },
  DefenseWeapons = {
    name = "Internal Defense Weapons"%_t,
    value = 0
  },
  FighterCargoPickup = {
    name = "Fighter Cargo Pickup"%_t,
    value = 0 -- boolean
  },
  PilotsPerFighter = {
    name = "Pilots Per Fighter"%_t,
    value = 1
  },
  MinersPerTurret = {
    name = "Miners Per Turret"%_t,
    value = 1
  },
  GunnersPerTurret = {
    name = "Gunners Per Turret"%_t,
    value = 1
  },
  MechanicsPerTurret = {
    name = "Mechanics Per Turret"%_t,
    value = 1
  },
  Engineers = {
    name = "Engineers"%_t,
    crew = "engineers"
  },
  Mechanics = {
    name = "Mechanics"%_t,
    crew = "mechanics"
  },
  Gunners = {
    name = "Gunners"%_t,
    crew = "gunners"
  },
  Miners = {
    name = "Miners"%_t,
    crew = "miners"
  },
  Security = {
    name = "Security /* as in an undefined amount of Security */"%_t,
    crew = "security"
  },
  Attackers = {
    name = "Boarders /* as in an undefined amount of Boarders */"%_t,
    crew = "attackers"
  },
  Sergeants = {
    name = "Sergeants /* as in an undefined amount of Sergeants */"%_t,
    crew = "sergeants"
  },
  Lieutenants = {
    name = "Lieutenants /* as in an undefined amount of Lieutenants */"%_t,
    crew = "lieutenants"
  },
  Commanders = {
    name = "Commanders /* as in an undefined amount of Commanders */"%_t,
    crew = "commanders"
  },
  Generals = {
    name = "Generals /* as in an undefined amount of Generals */"%_t,
    crew = "generals"
  },
  Captains = {
    name = "Captains /* as in an undefined amount of Captains */"%_t,
    crew = "captains"
  }
}

function BuffsHelper.formatTimeShort(seconds)
    seconds = math.floor(seconds)

    local days = math.floor(seconds / 86400)
    seconds = seconds - days * 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600

    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60

    local tbl = {days = days, hours = hours, minutes = minutes, seconds = seconds}
    if days > 0 then
        return "${days}d ${hours}h"%_t % tbl
    end
    if hours > 0 then
        return "${hours}h ${minutes}m"%_t % tbl
    end
    if minutes > 0 then
        return "${minutes}m ${seconds}s"%_t % tbl
    end
    return seconds.." ".."s /* Unit for seconds */"%_t % tbl
end

function BuffsHelper.formatBonusStat(type, stat, value, noSign) -- create correct description of buff effect
    if type == 1 or type == 2 then
        if type == 2 then
            value = value - 1
        end
        if stat == StatsBonuses.HyperspaceRechargeEnergy then
            value = -value
        end
        value = value * 100 -- 0.3 -> 30%
        return (value > 0 and "+"..value or value).."%"
    else
        local valueStr
        if stat == StatsBonuses.ScannerReach
          or stat == StatsBonuses.ScannerMaterialReach
          or stat == StatsBonuses.LootCollectionRange
          or stat == StatsBonuses.TransporterRange then
            valueStr = string.sub("+${distance} km"%_t, 2) % {distance = round(value / 100, 2)} -- to km
        elseif stat == StatsBonuses.HyperspaceRechargeEnergy then
            if not noSign then
                value = -value
            end
            valueStr = round(value, 2)
        elseif stat == StatsBonuses.HyperspaceCooldown or stat == StatsBonuses.ShieldTimeUntilRechargeAfterHit
          or stat == StatsBonuses.ShieldTimeUntilRechargeAfterDepletion then
            valueStr = round(value, 2).." ".."s /* Unit for seconds */"%_t
        elseif stat == StatsBonuses.GeneratedEnergy or stat == StatsBonuses.EnergyCapacity or stat == StatsBonuses.BatteryRecharge then
            if math.floor(value / 1000000000000) > 0 then
                valueStr = round(value / 1000000000000, 2).." T".."J /* Unit: Joule */"%_t
            elseif math.floor(value / 1000000000) > 0 then
                valueStr = round(value / 1000000000, 2).." G".."J /* Unit: Joule */"%_t
            elseif math.floor(value / 1000000) > 0 then
                valueStr = round(value / 1000000, 2).." M".."J /* Unit: Joule */"%_t
            elseif math.floor(value / 1000) > 0 then
                valueStr = round(value / 1000, 2).." K".."J /* Unit: Joule */"%_t
            else
                valueStr = round(value, 2).." ".."J /* Unit: Joule */"%_t
            end
        elseif stat == StatsBonuses.FighterCargoPickup or stat == StatsBonuses.ShieldImpenetrable then
            valueStr = value <= 0 and "No"%_t or "Yes"%_t
            noSign = true
        else
            valueStr = round(value, 2)
        end
        if noSign then
            return valueStr
        end
        return value > 0 and "+"..valueStr or valueStr
    end
end

function BuffsHelper.getBuffColor(buff)
    local c
    if buff.color then
        if buff.lowColor then -- gradient
            c = lerp(buff.duration, 5, 60, vec3(buff.lowColor.r, buff.lowColor.g, buff.lowColor.b), vec3(buff.color.r, buff.color.g, buff.color.b))
        else
            return buff.color
        end
    elseif buff.type == 5 then
        if buff.duration == -1 then
            c = vec3(0.9, 0.9, 0) -- yellow for permanent complex buffs
        else
            c = lerp(buff.duration, 5, 60, vec3(0.6, 0.6, 0.6), vec3(1, 1, 1)) -- grayish/white
        end
    elseif buff.isDebuff then
        if buff.duration == -1 then
            c = vec3(1, 0.5, 0) -- orange for permanent debuffs
        else
            c = lerp(buff.duration, 5, 60, vec3(1, 0.4, 0.4), vec3(1, 0, 0)) -- light red/red
        end
    else
        if buff.duration == -1 then
            c = vec3(0, 0.75, 1) -- light blue for permanent buffs
        else
            c = lerp(buff.duration, 5, 60, vec3(0.4, 1, 0.4), vec3(0, 1, 0)) -- light green/green
        end
    end
    return ColorRGB(c.x, c.y, c.z)
end

function BuffsHelper.createBuffTooltip(isPlayer, buff)
    if not BuffsHelper.CustomScriptByPath then -- cache index by path
        BuffsHelper.CustomScriptByPath = {}
        for _, v in pairs(BuffsHelper.Scripts) do
            if v.script then
                BuffsHelper.CustomScriptByPath[v.script] = v
            end
            if v.playerScript then
                BuffsHelper.CustomScriptByPath[v.playerScript] = v
            end
        end
    end

    local tooltip = Tooltip()
    local line = TooltipLine(20, 15)
    line.ltext = buff.name
    if buff.color then
        line.lcolor = buff.color
    elseif buff.type == 5 then
        line.lcolor = (buff.duration == -1) and ColorRGB(0.9, 0.9, 0) or ColorRGB(1, 1, 1) -- yellow/white
    elseif buff.isDebuff then
        line.lcolor = (buff.duration == -1) and ColorRGB(1, 0.5, 0) or ColorRGB(1, 0, 0) -- orange/red
    else
        line.lcolor = (buff.duration == -1) and ColorRGB(0, 0.75, 1) or ColorRGB(0.4, 1, 0.4) -- light blue/light green
    end
    line.rtext = buff.duration ~= -1 and BuffsHelper.formatTimeShort(buff.duration) or "Permanent"%_t
    tooltip:addLine(line)
    -- display bonuses
    if buff.type == 5 then -- complex buff
        for _, effect in ipairs(buff.effects) do
            line = TooltipLine(16, 13)
            local scriptPath = isPlayer and effect.playerScript or effect.script
            if scriptPath then -- custom script
                local effectScript = BuffsHelper.CustomScriptByPath[scriptPath]
                if effectScript and effectScript.displayName then
                    line.ltext = effectScript.displayName
                    if effectScript.tooltipFunc then
                        line.rtext = effectScript.tooltipFunc(isPlayer, unpack(effect.args))
                    end
                end
            elseif effect.customStat then -- custom stat
                local entityStat = BuffsHelper.Stats[effect.customStat]
                if entityStat and entityStat.displayName then
                    line.ltext = entityStat.displayName
                    if entityStat.tooltipFunc then
                        line.rtext = entityStat.tooltipFunc(isPlayer, unpack(effect.args))
                    end
                end
            elseif effect.stat then -- vanilla StatsBonuses
                line.ltext = BuffsHelper.BonusesDisplay[BuffsHelper.BonusNameByIndex[effect.stat]].name
                line.rtext = BuffsHelper.formatBonusStat(effect.type, effect.stat, effect.value)
            end
            tooltip:addLine(line)
        end
    else
        line = TooltipLine(16, 13)
        line.ltext = BuffsHelper.BonusesDisplay[BuffsHelper.BonusNameByIndex[buff.stat]].name
        line.rtext = BuffsHelper.formatBonusStat(buff.type, buff.stat, buff.value)
        tooltip:addLine(line)
    end
    --
    if buff.desc then
        tooltip:addLine(TooltipLine(6, 6)) -- empty line to separate bonuses from description
        for j = 1, #buff.desc do
            line = TooltipLine(15, 13)
            line.ltext = buff.desc[j]
            tooltip:addLine(line)
        end
    end
    return tooltip
end

end


-- ENUMS --

--- Buff type.
-- StatBonuses are calculated using the following formula:
-- 
-- resultingValue = (baseValue × BaseMultiplier + MultiplyableBias) × Multiplier + AbsoluteBias
-- table: Type
BuffsHelper.Type = {
  BaseMultiplier = 1, -- Multiplyer for stat of type type. This is to increase a stat, so a factor of 0.3 will become 1.3
  Multiplier = 2, -- Multiplyer for stat of type type. The factor will be used unchanged
  MultiplyableBias = 3, -- Bias for stat of type type. This bias will be added to stat before multipliers are considered
  AbsoluteBias = 4, -- Flat bias for stat of type type. This bias will be added to stat after multipliers are considered
  Buff = 5 -- Complex buff with multiple bonuses or custom stats/scripts
}

--- Buff apply mode.
-- table: Mode
BuffsHelper.Mode = {
  Add = 1, -- Add if doesn't exist
  AddOrRefresh = 2, -- Refresh duration or add if doesn't exist
  AddOrCombine = 3, -- Combine duration or add if doesn't exist
  Refresh = 4, -- Refresh duration, don't add if doesn't exist
  Combine = 5 -- Combine duration, don't add if doesn't exist
}

--- Buff target.
-- This is used only for Player-buffs. It defines which target should a buff affect and if it should spread to an entity.
-- 
-- StatsBonuses (vanilla bonuses) always have Target.Entity, which means that they don't do anything for player, but spread to the currently piloted ship BuffsHelper.Scripts and BuffsHelper.Stats can have various Target values.
-- table: Target
BuffsHelper.Target = {
  Entity = 1, -- Doesn't affect player, but spreads to a currently piloted entity
  Player = 2, -- Doesn't spread to an entity, just stays on a player and affects them
  Both = 3 -- Affects player, spreads to an entity and affects it too (maybe in a different way)
}


-- SERVER API --

if isServer then

--- Adds a complex buff that can include multiple stat bonuses, custom stats and custom scripts.
-- Server-side: This function is only available on the server.
-- !Player/Entity: object — Buff target
-- !string: name — Buff name, can't contain dots; If it starts with an underscore, the buff will be hidden (will not be sent to client side)
-- !table: effects — Table where each element can be either a vanilla bonus, custom stat or custom script. For custom scripts and stats use BuffsHelper.Scripts.Name:New/NewTarget(...) and BuffsHelper.Stats.Name:New/NewTarget(...). For vanilla bonus pass a table with following values:
-- 
-- * BuffsHelper.Type type
-- * StatsBonuses stat
-- * float value
-- !float: duration *(optional)* — Duration in seconds (default: -1 = permanent)
-- !Mode: applyMode *(optional)* — Apply mode (default: 1 = Mode.Add)
-- !boolean: isAbsoluteDecay *(optional)* — If true, buff will decay even while sector with ship is unloaded (default: false). Note: Player-attached buffs cannot have this argument set to 'true'
-- !string: icon *(optional)* — Icon name. Icon should be in the "data/textures/icons/buffs/" folder (default: "Buff")
-- !string: description *(optional)* — Buff description, long descriptions should be separated into lines with '\n'. I advise to register your descriptions in the "BuffsIntegration.lua" instead
-- !table: descArgs *(optional)* — Table of arguments for description
-- !Color: color *(optional)* — Custom icon and title color, should be an int (example: 0xff0000ff - blue)
-- !Color: lowDurationColor *(optional)* — Custom color that will be used in a gradient with previous color when there are < 60 seconds left
-- !int: priority *(optional)* — Display priority, higher value = earlier in the list; If it's -1000, a buff will be hidden abd won't be sent to client (default: 0)
-- treturn: var result
-- 
-- * true - Successfully added/updated buff
-- * false - If applyMode = 1, buff already exists. If applyMode is 4 or 5, buff wasn't updated because it doesn't exist
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 0 - You tried to add buff before game called `restore` function. Your request will be processed later and you will not be able to get return values
-- * 1 - Names can't contain '.'
-- * 2 - Ran out of keys, can't add more than 1000 bonuses
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
-- usage: BuffsHelper.addBuff(ship, "Sturdy Build"%_T, {
--    { BuffsHelper.Type.AbsoluteBias, StatsBonuses.CargoHold, 50 },
--    { BuffsHelper.Type.BaseMultiplier, StatsBonuses.EnergyCapacity, 0.1 },
--    BuffsHelper.Scripts.ChangeDurability:New(20, 5),
--    BuffsHelper.Stats.HullDurability:New(0.5)
--  }, -1, BuffsHelper.Mode.Add, false, "SturdyBuild",
--  "Sturdy high-quality craft produced on a\nshipyard in the sector ${sector}.",
--  { sector = "(133:425)" })
-- usage: BuffsHelper.addBuff(player, "Inspired"%_T, {
--    { BuffsHelper.Type.BaseMultiplier, StatsBonuses.HyperspaceCooldown, -0.1 },
--    BuffsHelper.Stats.SetValue:NewTarget(BuffsHelper.Target.Both, "is_inspired", true)
--  }, 60 * 10, BuffsHelper.Mode.AddOrRefresh, false, "Inspired",
--  "You feel a rush of inspiration, engage towards new discoveries!")
function BuffsHelper.addBuff(object, ...)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "_addBuff", ...)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Acts in a similar fashion to 'Entity():addBaseMultiplier', adding a simple vanilla stat buff.
-- Server-side: This function is only available on the server.
-- !Player/Entity: object — Buff target
-- !string: name — Buff name, can't contain dots; If it starts with an underscore, the buff will be hidden (will not be sent to client side)
-- !StatsBonuses: stat — Stat index
-- !float: value — Bonus value/factor
-- !float: duration *(optional)* — Duration in seconds (default: -1 = permanent)
-- !Mode: applyMode *(optional)* — Apply mode (default: 1 = Mode.Add)
-- !boolean: isAbsoluteDecay *(optional)* — If true, buff will decay even while sector with ship is unloaded (default: false). Note: Player-attached buffs cannot have this argument set to 'true'
-- !string: icon *(optional)* — Icon name. Icon should be in the "data/textures/icons/buffs/" folder (default: "Buff")
-- !string: description *(optional)* — Buff description, long descriptions should be separated into lines with '\n'. I advise to register your descriptions in the "BuffsIntegration.lua" instead
-- !table: descArgs *(optional)* — Table of arguments for description
-- !Color: color *(optional)* — Custom icon and title color, should be an int (example: 0xff0000ff - blue)
-- !Color: lowDurationColor *(optional)* — Custom color that will be used in a gradient with previous color when there are < 60 seconds left
-- !int: priority *(optional)* — Display priority, higher value = earlier in the list; If it's -1000, a buff will be hidden abd won't be sent to client (default: 0)
-- treturn: var result
-- 
-- * true - Successfully added/updated buff
-- * false - If applyMode = 1, buff already exists. If applyMode is 4 or 5, buff wasn't updated because it doesn't exist
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 0 - You tried to add buff before game called `restore` function. Your request will be processed later and you will not be able to get return values
-- * 1 - Names can't contain '.'
-- * 2 - Ran out of keys, can't add more than 1000 bonuses
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
-- usage: BuffsHelper.addBaseMultiplier(ship, "Faster Than Light"%_T, StatBonuses.HyperspaceReach, 5, 60, BuffsHelper.Mode.Add, false, "FasterThanLight",
--  "Your jump drive is boosted for a short time.")
function BuffsHelper.addBaseMultiplier(object, ...)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "_addBaseMultiplier", ...)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the addBaseMultiplier function but manipulates Multiplier instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
-- !StatsBonuses: stat
-- !float: value 
-- !float: duration *(optional)*
-- !Mode: applyMode *(optional)*
-- !boolean: isAbsoluteDecay *(optional)*
-- !string: icon *(optional)*
-- !string: description *(optional)*
-- !table: descArgs *(optional)*
-- !Color: color *(optional)*
-- !Color: lowDurationColor *(optional)*
-- !int: priority *(optional)*
function BuffsHelper.addMultiplier(object, ...)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "_addMultiplier", ...)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the addBaseMultiplier function but manipulates MultiplyableBias instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
-- !StatsBonuses: stat
-- !float: value 
-- !float: duration *(optional)*
-- !Mode: applyMode *(optional)*
-- !boolean: isAbsoluteDecay *(optional)*
-- !string: icon *(optional)*
-- !string: description *(optional)*
-- !table: descArgs *(optional)*
-- !Color: color *(optional)*
-- !Color: lowDurationColor *(optional)*
-- !int: priority *(optional)*
function BuffsHelper.addMultiplyableBias(object, ...)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "_addMultiplyableBias", ...)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the addBaseMultiplier function but manipulates AbsoluteBias instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
-- !StatsBonuses: stat
-- !float: value 
-- !float: duration *(optional)*
-- !Mode: applyMode *(optional)*
-- !boolean: isAbsoluteDecay *(optional)*
-- !string: icon *(optional)*
-- !string: description *(optional)*
-- !table: descArgs *(optional)*
-- !Color: color *(optional)*
-- !Color: lowDurationColor *(optional)*
-- !int: priority *(optional)*
function BuffsHelper.addAbsoluteBias(object, ...)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "_addAbsoluteBias", ...)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Removes a complex buff from a specified object
-- Server-side: This function is only available on the server.
-- !Player/Entity: object — Buff target
-- !string: name — Buff name
-- treturn: var result
-- 
-- * true - Successfully removed
-- * false - Buff doesn't exist
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 0 - You tried to remove buff before game called `restore` function. Your request will be processed later and you will not be able to get return values
-- * 1 - Names can't contain '.'
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.removeBuff(object, name)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBonus", "B_"..name)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Removes Base Multiplier from a specified object
-- Server-side: This function is only available on the server.
-- !Player/Entity: object — Buff target
-- !string: name — Buff name
-- treturn: var result
-- 
-- * true - Successfully removed
-- * false - Buff doesn't exist
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 0 - You tried to remove buff before game called `restore` function. Your request will be processed later and you will not be able to get return values
-- * 1 - Names can't contain '.'
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.removeBaseMultiplier(object, name)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBonus", "BM_"..name)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the removeBaseMultiplier function but removes Multiplier instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
function BuffsHelper.removeMultiplier(object, name)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBonus", "M_"..name)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the removeBaseMultiplier function but removes MultiplyableBias instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
function BuffsHelper.removeMultiplyableBias(object, name)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBonus", "MB_"..name)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Has the same arguments and return values as the removeBaseMultiplier function but removes AbsoluteBias instead
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- !string: name
function BuffsHelper.removeAbsoluteBias(object, name)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBonus", "AB_"..name)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Removes a buff of a certain type from a specified object
-- Server-side: This function is only available on the server.
-- !Player/Entity: object — Buff target
-- !string: name — Buff name
-- !Type: buffType — Buff type
-- treturn: var result
-- 
-- * true - Successfully removed
-- * false - Buff doesn't exist
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 0 - You tried to remove buff before game called `restore` function. Your request will be processed later and you will not be able to get return values
-- * 1 - Names can't contain '.'
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.removeBuffWithType(object, name, buffType)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "removeBuffWithType", name, buffType)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Returns true/false depending on if mod is ready to apply buffs without delaying them (pending)
-- Server-side: This function is only available on the server.
-- !Player/Entity: object
-- treturn: var result
-- 
-- * true - Ready
-- * false - Not ready
-- * nil - Error, look at the second return value
-- treturn: int errorCode
-- 
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.isReady(object)
    local status, ret1 = object:invokeFunction("buffs.lua", "isReady")
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1
end

-- CALLBACKS --

--- Fires after 'restore' signalizing that mod is ready to process requests without delays.
-- Server-side: This function is only available on the server.
-- callback: onBuffsReady
-- !Player/Entity: objectIndex — Player or Entity index, depends on which object you registered a callback
-- !table: buffs — Contains all previously stored buffs and pending buffs that were just applied
-- !boolean: isFirstLaunch — If true, the mod was just added to an object
-- !boolean: isLate — If true, you added this callback a bit too late and missed an actual 'restore' (or the buffs script was just added and didnt't have any stored data)
-- usage: object:registerCallback("onBuffsReady", "yourHandlerFunctionName")

--- Fires after a buff of any kind was applied.
-- Server-side: This function is only available on the server.
-- callback: onBuffApplied
-- !Player/Entity: objectIndex — Player or Entity index, depends on which object you registered a callback
-- !Type: buffType — Buff type from the 'BuffsHelper.Type' enum
-- !Mode: applyMode — Apply mode from 'BuffsHelper.Mode' enum
-- !table: buff — The buff itself
-- !table: previous — Old values of changed args (like duration or color). If it's nil, it means that it's a new buff (so basically everything in the 'buff' table was 'changed')
-- usage: object:registerCallback("onBuffApplied", "yourHandlerFunctionName")

--- Fires after a buff was removed (via script or via natural duration decay).
-- Server-side: This function is only available on the server.
-- callback: onBuffRemoved
-- !Player/Entity: objectIndex — Player or Entity index, depends on which object you registered a callback
-- !Type: buffType — Buff type from the 'BuffsHelper.Type' enum
-- !table: buff — The buff itself
-- usage: object:registerCallback("onBuffRemoved", "yourHandlerFunctionName")

end


-- CLIENT/SERVER API --

--- Returns all buffs as a table. If called before `restore`, will return empty table.
-- !Player/Entity: object
-- treturn: table result - A table that contains all buffs
-- treturn: var errorCode
-- 
-- * nil - Everything is fine.
-- * 0 - You called the function before game called `restore`, that's why the first argument is an empty table
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.getBuffs(object)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "getBuffs")
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end

--- Returns specified buff.
-- !Player/Entity: object — Entity if it's an entity buff or Player if it's a player buff
-- !string: name — Buff name
-- !Type: type *(optional)* — Buff type. 'nil' means 'any type' (default: nil)
-- treturn: var result
-- 
-- * table - Buff table
-- * nil - Couldn't find a buff or you called the function before game called `restore`
-- treturn: var errorCode
-- 
-- * nil - Everything is fine.
-- * 0 - You called the function before game called `restore`, that's why the first argument is an empty table
-- * 1 - Names can't contain '.'
-- * 11 - The call failed because the object with the specified index does not exist or has no scripting component
-- * 12 - The call failed because it came from another sector than the object is in
-- * 13 - The call failed because the given script was not found in the object
-- * 14 - The call failed because the given function was not found in the script
-- * 15 - The call failed because the script's state has errors and is invalid
function BuffsHelper.getBuff(object, name, type)
    local status, ret1, ret2 = object:invokeFunction("buffs.lua", "getBuff", name, type)
    if status ~= 0 then
        return nil, status + 10
    end
    return ret1, ret2
end


-- CUSTOM STATS --
BuffsHelper.Stats = {}

--- Adds custom stat effect for client and server.
--
-- Custom stats do something when applied and when their buff ends/removed.
-- They don't attach a script to an object so they can't have callbacks/update functions but they are more performance-friendly.
-- Also they can be displayed in the ship buffs tab.
-- localfunction: addStat
-- !string: enumName — A name to be used as 'BuffsHelper.Stats.EnumName'
-- !string: displayName — A name that will be translated and displayed in a tooltip.
-- !function: onApply(Player player, Entity entity, var.. customArgs) — A function that will be executed when a buff will be applied 
-- !function: onRemove(Player player, Entity entity, var.. customArgs) — A function that will be executed when a buff will be removed (via script or via natural decay)
-- !function: tooltipFunc *(optional)* — Function that returns tooltip string with bonus value
-- !Target: showInStats *(optional)* — Determines if a stat should be shown in the Player/Ship window Buffs tab or both; 'nil' = 'don't show' (default: nil)
-- !function: statsFunc *(optional)* — If defined, buff will be shown in the ship/player stats window
-- usage: addStat("Perception", "Perception"%_t, 
--  function(player, entity, value) if entity then addStatEntity() else addStatPlayer() end end,
--  function(player, entity, value) if entity then removeStatEntity() else removeStatPlayer() end end,
--  function(isPlayer, factor) return formatStatFactor(factor) end,
--  BuffsHelper.Target.Both,
--  function(player, entity)
--      if entity then
--          return getBaseEntityStat(), getFinalEntityStat()
--      else
--          return getBasePlayerStat(), getFinalPlayerStat()
--      end
--  end)
local function addStat(enumName, displayName, onApply, onRemove, tooltipFunc, showInStats, statsFunc)
    local stat = {
      displayName = displayName
    }
    if isServer then
        stat.enumName = enumName
        stat.onApply = onApply
        stat.onRemove = onRemove
        stat.New = function(self, ...)
            return { customStat = self.enumName, args = {...} }
        end
        stat.NewTarget = function(self, target, ...)
            return { customStat = self.enumName, target = target, args = {...} }
        end
    else -- onClient
        stat.tooltipFunc = tooltipFunc
        stat.showInStats = showInStats
        stat.statsFunc = statsFunc
    end
    BuffsHelper.Stats[enumName] = stat
end

-- Built-in custom stats:

--- Increases/decreases all incoming damage.
--
-- Can be applied to a player, but will do nothing.
-- customstat: DamageMultiplier
-- !float: factor — Extra damage factor (0.2 = +20%)
-- usage: BuffsHelper.Stats.DamageMultiplier:New(0.2)
-- usage: BuffsHelper.Stats.DamageMultiplier:NewTarget(BuffsHelper.Target.Entity, 0.15)
addStat("DamageMultiplier", "Damage"%_t,
  function(player, entity, value) -- onApply
      if entity then
          entity.damageMultiplier = entity.damageMultiplier + value
      end
  end,
  function(player, entity, value) -- onRemove
      if entity then
          entity.damageMultiplier = entity.damageMultiplier - value
      end
  end,
  function(isPlayer, factor) -- tooltipFunc
      factor = tonumber(string.format("%.2f", factor * 100)) -- 3 will be displayed as 3 and not 3.00
      return factor > 0 and "+"..factor.."%" or factor.."%"
  end,
  BuffsHelper.Target.Entity,
  function(player, entity) -- statsFunc
      if player then return end -- return nil = don't show this stat in the player buffs tab
      local result = tonumber(string.format("%.2f", entity.damageMultiplier * 100))
      return '100%', result..'%'
  end
)

--- Increases/decreases hull durability multiplier.
--
-- Can be applied to a player, but will do nothing.
-- customstat: HullDurability
-- !float: factor — Extra hull durability factor (0.2 = +20%)
-- usage: BuffsHelper.Stats.HullDurability:New(0.2)
-- usage: BuffsHelper.Stats.HullDurability:NewTarget(BuffsHelper.Target.Entity, 0.15)
addStat("HullDurability", "Hull Durability"%_t,
  function(player, entity, value)
      if entity then
          local dur = Durability(entity)
          if dur then
              dur.maxDurabilityFactor = dur.maxDurabilityFactor + value
          end
      end
  end,
  function(player, entity, value)
      if entity then
          local dur = Durability(entity)
          if dur then
              dur.maxDurabilityFactor = dur.maxDurabilityFactor - value
          end
      end
  end,
  function(isPlayer, factor)
      factor = tonumber(string.format("%.2f", factor * 100)) -- 3 will be displayed as 3 and not 3.00
      return factor > 0 and "+"..factor.."%" or factor.."%"
  end,
  BuffsHelper.Target.Entity,
  function(player, entity) -- statsFunc
      if player then return end -- return nil = don't show this stat in the player buffs tab
      local dur = Durability(entity)
      local result = '?'
      if dur then
          result = tonumber(string.format("%.2f", dur.maxDurabilityFactor * 100))
      end
      return '100%', result..'%'
  end
)

--- Allows to increase/decrease object values via 'setValue'/'getValue'.
-- customstat: ChangeValue
-- !string: name — Variable name
-- !float: value — Variable numeric value
-- usage: BuffsHelper.Stats.ChangeValue:New("scan_level", 4)
-- usage: BuffsHelper.Stats.ChangeValue:NewTarget(BuffsHelper.Target.Player, "scan_level", 2)
addStat("ChangeValue", nil,
  function(player, entity, name, value)
      local object = player or entity
      local val = object:getValue(name) or 0
      object:setValue(name, val + value)
  end,
  function(player, entity, name, value)
      local object = player or entity
      local val = object:getValue(name) or 0
      object:setValue(name, val - value)
  end
)

--- Allows to set object values via 'setValue'/'getValue'.
-- customstat: SetValue
-- !string: name — Variable name
-- !var: value — Variable value
-- usage: BuffsHelper.Stats.SetValue:New("hidden_name", "Bob")
-- usage: BuffsHelper.Stats.SetValue:NewTarget(BuffsHelper.Target.Both, "hidden_name", "Bob")
addStat("SetValue", nil,
  function(player, entity, name, value)
      local object = player or entity
      object:setValue(name, value)
  end,
  function(player, entity, name, value)
      local object = player or entity
      object:setValue(name)
  end
)


-- CUSTOM SCRIPTS --
BuffsHelper.Scripts = {}

--- Adds custom script effect for client and server.
--
-- Custom scripts are attached to an entity or player. 
-- They can have callbacks or affect their object over time (update function) but they also consume more CPU and RAM.
-- localfunction: addScript
-- !string: enumName — A name to be used as 'BuffsHelper.Scripts.EnumName'
-- !string: displayName — A name that will be translated and displayed in a tooltip.
-- !string: scriptName *(optional)* — A script name without path and '.lua'. File should be in the "data/scripts/entity/buffs/" folder. If nil, this custom script cannot be attached to an entity.
-- !string: playerScriptName *(optional)* — A script name without path and '.lua'. File should be in the "data/scripts/player/buffs/" folder. If nil, this custom script cannot be attached to a player.
-- !function: tooltipFunc *(optional)* — Function that returns tooltip string with bonus value
-- usage: addScript("Perception", "Perception"%_t, "perceptionship", "perceptionplayer",
--  function(isPlayer, factor) return formatScriptFactor(factor) end)
local function addScript(enumName, displayName, scriptName, playerScriptName, tooltipFunc)
    local script = {
      script = scriptName,
      playerScript = playerScriptName,
      displayName = displayName
    }
    if isServer then
        script.New = function(self, ...)
            return { script = self.script, args = {...} }
        end
        script.NewTarget = function(self, target, ...)
            local r = { args = {...} }
            if target ~= BuffsHelper.Target.Player then
                r.script = self.script
            end
            if target == BuffsHelper.Target.Player or target == BuffsHelper.Target.Both then
                r.playerScript = self.playerScript
            end
            return r
        end
    else -- onClient
        script.tooltipFunc = tooltipFunc
    end
    BuffsHelper.Scripts[enumName] = script
end

-- Built-in custom scripts:

--- Inflicts extra damage to other ship on collision.
--
-- Can be applied to a player, but will do nothing.
-- customscript: CollisionDamage
-- !float: amount — Collision damage amount
-- usage: BuffsHelper.Stats.CollisionDamage:New(4)
-- usage: BuffsHelper.Stats.CollisionDamage:NewTarget(BuffsHelper.Target.Both, 5)
addScript("CollisionDamage", "Collision Damage"%_t, "collisiondamage", nil,
  function(isPlayer, amount)
      return "+"..amount
  end
)

--- Destroys random cargo 'volume' every 'frequency' seconds.
--
-- Can be applied to a player, but will do nothing.
-- customscript: DestroyCargo
-- !float: volume — Cargo volume to destroy, should be positive
-- !float: frequency — Time interval, should be positive
-- usage: BuffsHelper.Stats.DestroyCargo:New(10, 5)
-- usage: BuffsHelper.Stats.DestroyCargo:NewTarget(BuffsHelper.Target.Both, 20, 4)
addScript("DestroyCargo", "Cargo Destruction"%_t, "destroycargo", nil,
  function(isPlayer, volume, frequency)
      volume = tonumber(string.format("%.2f", volume / frequency)) -- 3 will be displayed as 3 and not 3.00
      frequency = ("${amount}/s"%_t) % { amount = volume }
      return volume > 0 and "+"..frequency or frequency
  end
)

--- Kills 'amount' random crew members every 'frequency' seconds.
--
-- Can be applied to a player, but will do nothing.
-- customscript: KillCrew
-- !int: amount — Crew amount to kill, should be positive
-- !float: frequency — Time interval, should be positive
-- usage: BuffsHelper.Stats.KillCrew:New(10, 5)
-- usage: BuffsHelper.Stats.KillCrew:NewTarget(BuffsHelper.Target.Entity, 20, 4)
addScript("KillCrew", "Crew Dies"%_t, "killcrew", nil,
  function(isPlayer, amount, frequency)
      amount = tonumber(string.format("%.2f", amount / frequency))
      frequency = ("${amount}/s"%_t) % { amount = amount }
      return amount > 0 and "+"..frequency or frequency
  end
)
--- Changes hull durability by 'amount' every 'frequency' seconds.
--
-- Can be applied to a player, but will do nothing.
-- customscript: ChangeDurability
-- !int: amount — Hull change amount
-- !float: frequency — Time interval, should be positive
-- usage: BuffsHelper.Stats.ChangeDurability:New(10, 5)
-- usage: BuffsHelper.Stats.ChangeDurability:NewTarget(BuffsHelper.Target.Entity, 20, 4)
addScript("ChangeDurability", "Durability"%_t, "changedurability", nil,
  function(isPlayer, amount, frequency)
      amount = tonumber(string.format("%.2f", amount / frequency))
      frequency = ("${amount}/s"%_t) % { amount = amount }
      return amount > 0 and "+"..frequency or frequency
  end
)

--- Changes shield durability by 'amount' every 'frequency' seconds.
--
-- Can be applied to a player, but will do nothing.
-- customscript: ChangeShield
-- !int: amount — Shield change amount
-- !float: frequency — Time interval, should be positive
-- usage: BuffsHelper.Stats.ChangeShield:New(10, 5)
-- usage: BuffsHelper.Stats.ChangeShield:NewTarget(BuffsHelper.Target.Entity, 20, 4)
addScript("ChangeShield", "Shield"%_t, "changeshield", nil,
  function(isPlayer, amount, frequency)
      amount = tonumber(string.format("%.2f", amount / frequency))
      frequency = ("${amount}/s"%_t) % { amount = amount }
      return amount > 0 and "+"..frequency or frequency
  end
)

return BuffsHelper