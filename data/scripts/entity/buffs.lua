package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
include("stringutility")
local Azimuth = include("azimuthlib-basic")
local BuffsHelper = include("BuffsHelper")

-- namespace Buffs
Buffs = {}

local buffPrefixes = {"BM_", "M_", "MB_", "AB_", "_B"}

if onClient() then


local buffDescriptions = include("BuffsIntegration")

local configOptions = {
  _version = {default = "0.1", comment = "Config version. Don't touch."},
  LogLevel = {default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."},
}
local config, isModified = Azimuth.loadConfig("Buffs", configOptions)
if isModified then
    Azimuth.saveConfig("Buffs", config, configOptions)
end
local Log = Azimuth.logs("Buffs", config.LogLevel)


local stats = {
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
  "Captains"
}
local statNames = {
  RadarReach = "Radar Range"%_t,
  HiddenSectorRadarReach = "Deep Scan Range"%_t,
  ScannerReach = "Scanner Range"%_t,
  ScannerMaterialReach = "Material Scanner Range"%_t,
  HyperspaceReach = "Jump Range"%_t,
  HyperspaceCooldown = "Hyperspace Cooldown"%_t,
  HyperspaceRechargeEnergy = "Recharge Energy"%_t,
  ShieldDurability = "Shield Durability"%_t,
  ShieldRecharge = "Shield Recharge Rate"%_t,
  ShieldTimeUntilRechargeAfterHit = "Time Until Recharge"%_t,
  ShieldTimeUntilRechargeAfterDepletion = "Time Until Recharge (Depletion)"%_t,
  ShieldImpenetrable = "Impenetrable Shields"%_t,
  Velocity = "Velocity"%_t,
  Acceleration = "Acceleration"%_t,
  GeneratedEnergy = "Generated Energy"%_t,
  EnergyCapacity = "Energy Capacity"%_t,
  BatteryRecharge = "Recharge Rate"%_t,
  ArbitraryTurrets = "Armed or Unarmed Turret Slots"%_t,
  UnarmedTurrets = "Unarmed Turret Slots"%_t,
  ArmedTurrets = "Armed Turret Slots"%_t,
  CargoHold = "Cargo Hold"%_t,
  LootCollectionRange = "Loot Collection Range"%_t,
  TransporterRange = "Docking Distance"%_t,
  FighterCargoPickup = "Fighter Cargo Pickup"%_t,
  PilotsPerFighter = "Pilots Per Fighter"%_t,
  MinersPerTurret = "Miners Per Turret"%_t,
  GunnersPerTurret = "Gunners Per Turret"%_t,
  MechanicsPerTurret = "Mechanics Per Turret"%_t,
  Engineers = "Engineers"%_t,
  Mechanics = "Mechanics"%_t,
  Gunners= "Gunners"%_t,
  Miners = "Miners"%_t,
  Security = "Security"%_t,
  Attackers = "Boarders"%_t,
  Sergeants = "Sergeants"%_t,
  Lieutenants = "Lieutenants"%_t,
  Commanders = "Commanders"%_t,
  Generals = "Generals"%_t,
  Captains = "Captains"%_t
}
local customEffects = {}
for _, v in pairs(BuffsHelper.Custom) do
    customEffects[v.script] = v
end
local buffs = {}
local buffsCount = 0
local hoveredBuffTooltip, prevHoveredName
local distanceString = "+${distance} km"%_t
distanceString = distanceString:sub(2)

local function getBonusStatString(type, stat, value) -- create correct description of buff effect
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
        local valueStr = value
        if stat == StatsBonuses.ScannerReach
          or stat == StatsBonuses.ScannerMaterialReach
          or stat == StatsBonuses.LootCollectionRange
          or stat == StatsBonuses.TransporterRange
          or stat == StatsBonuses.FighterCargoPickup then
            valueStr = distanceString % {distance = value / 100} -- to km
        elseif stat == StatsBonuses.HyperspaceRechargeEnergy then
            value = -value
            valueStr = value
        end
        return value > 0 and "+"..valueStr or valueStr
    end
end

function Buffs.getUpdateInterval()
    return 0.2
end

function Buffs.initialize()
    Player():registerCallback("onPostRenderHud", "onRenderHud")
    Entity():registerCallback("onCraftSeatEntered", "onCraftSeatEntered")

    if Player().craftIndex == Entity().index then
        invokeServerFunction("refreshData")
    end
end

function Buffs.update(timePassed)
    if Player().craftIndex ~= Entity().index then return end
    if buffsCount == 0 then return end

    local mousePos = Mouse().position
    local res = getResolution()
    local rx, ry
    local i = 0 -- buff number, affects position
    local found = false -- if at least one buff was hovered
    local white = ColorRGB(1, 1, 1)
    local red = ColorRGB(1, 0, 0)
    local green = ColorRGB(0, 1, 0)
    local customEffect
    for name, buff in pairs(buffs) do
        -- decay buffs
        for name, buff in pairs(buffs) do
            if buff.duration ~= -1 then
                buff.redraw = math.floor(buff.duration)
                buff.duration = math.max(0, buff.duration - timePassed)
                buff.redraw = buff.redraw - math.floor(buff.duration)
            end
        end
        -- check mouse hover
        if not found then
            rx = res.x / 2 + 270 + math.floor(i / 2) * 30
            ry = res.y - 65 + (i % 2) * 30

            if mousePos.x >= rx and mousePos.x <= rx + 25 and mousePos.y >= ry and mousePos.y <= ry + 25 then
                found = true
                if buff.redraw == 1 or prevHoveredName ~= name then
                    prevHoveredName = name

                    local tooltip = Tooltip()
                    local line = TooltipLine(20, 15)
                    line.ltext = buff.name
                    if buff.type == 5 then
                        line.lcolor = buff.color and buff.color or white
                    else
                        line.lcolor = buff.isDebuff and red or green
                    end
                    line.rtext = buff.duration ~= -1 and string.format("%ss"%_t, math.floor(buff.duration)) or "Permanent"%_t
                    tooltip:addLine(line)
                    -- display bonuses
                    if buff.type == 5 then -- complex buff
                        for _, effect in ipairs(buff.effects) do
                            line = TooltipLine(16, 13)
                            if effect.script then -- custom effect
                                customEffect = customEffects[effect.script]
                                if customEffect then
                                    line.ltext = customEffect.statName
                                    if customEffect.statFunc then
                                        line.rtext = customEffect.statFunc(unpack(effect.args))
                                    end
                                end
                            else
                                line.ltext = statNames[stats[effect.stat+1]]
                                line.rtext = getBonusStatString(effect.type, effect.stat, effect.value)
                            end
                            tooltip:addLine(line)
                        end
                    else
                        line = TooltipLine(16, 13)
                        line.ltext = statNames[stats[buff.stat+1]]
                        line.rtext = getBonusStatString(buff.type, buff.stat, buff.value)
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
                    hoveredBuffTooltip = TooltipRenderer(tooltip)
                end
            end
        end
        i = i + 1
    end
    if not found then
        prevHoveredName = nil
        hoveredBuffTooltip = nil
    end
end

function Buffs.receiveData(_buffs)
    Log.Debug("receiveData: %s", Log.isDebug and Azimuth.serialize(_buffs) or '')
    buffsCount = 0
    buffs = _buffs
    for _, buff in pairs(buffs) do
        buffsCount = buffsCount + 1
        -- custom color
        if buff.color then
            buff.color = ColorInt(buff.color)
        else
            buff.color = nil
        end
        if buff.lowColor then
            buff.lowColor = ColorInt(buff.lowColor)
        else
            buff.lowColor = nil
        end
        -- icon
        if buff.type == 5 then
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or "Buff") .. ".png"
        else
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or stats[buff.stat+1]) .. ".png"
            -- check if it's a debuff, only simple buffs can be detected as positive/negative
            if buff.stat == StatsBonuses.HyperspaceCooldown
              or buff.stat == StatsBonuses.HyperspaceRechargeEnergy
              or buff.stat == StatsBonuses.ShieldTimeUntilRechargeAfterHit
              or buff.stat == StatsBonuses.ShieldTimeUntilRechargeAfterDepletion
              or buff.stat == StatsBonuses.PilotsPerFighter
              or buff.stat == StatsBonuses.MinersPerTurret
              or buff.stat == StatsBonuses.GunnersPerTurret
              or buff.stat == StatsBonuses.MechanicsPerTurret then
                if buff.type == 2 then
                    buff.isDebuff = buff.value > 1
                else
                    buff.isDebuff = buff.value > 0
                end
            else
                if buff.type == 2 then
                    buff.isDebuff = buff.value < 1
                else
                    buff.isDebuff = buff.value < 0
                end
            end
        end
        -- description
        if not buff.desc then
            buff.desc = buffDescriptions[buff.name]
        else
            buff.desc = buff.desc%_t
        end
        if buff.desc then
            if buff.descArgs then
                buff.desc = buff.desc % buff.descArgs
            end
            buff.desc = buff.desc:split("\n")
        end
        -- name
        buff.name = buff.name%_t
    end
end

-- CALLBACKS --
function Buffs.onRenderHud()
    if Player().craftIndex ~= Entity().index then return end
    if buffsCount == 0 then return end

    local renderer = UIRenderer()
    local res = getResolution()
    local i = 0
    local green = vec3(0, 1, 0)
    local lightGreen = vec3(0.4, 1, 0.4)
    local red = vec3(1, 0, 0)
    local lightRed = vec3(1, 0.4, 0.4)
    local white = vec3(1, 1, 1)
    local grayish = vec3(0.6, 0.6, 0.6)
    local yellow = vec3(0.9, 0.9, 0)
    local orange = vec3(1, 0.5, 0)
    local lightBlue = vec3(0, 0.75, 1)
    local rx, c
    for k, buff in pairs(buffs) do
        rx = res.x / 2 + 270 + math.floor(i / 2) * 30
        if rx + 35 > res.x then break end -- can't draw more
        if buff.color then
            if buff.lowColor then -- gradient
                c = lerp(buff.duration, 5, 60, vec3(buff.lowColor.r, buff.lowColor.g, buff.lowColor.b), vec3(buff.color.r, buff.color.g, buff.color.b))
                renderer:renderPixelIcon(vec2(rx, res.y - 65 + (i % 2) * 30), ColorRGB(c.x, c.y, c.z), buff.icon)
            else
                renderer:renderPixelIcon(vec2(rx, res.y - 65 + (i % 2) * 30), buff.color, buff.icon)
            end
        else
            if buff.type == 5 then
                if buff.duration == -1 then
                    c = yellow -- orange for permanent complex buffs
                else
                    c = lerp(buff.duration, 5, 60, grayish, white)
                end
            elseif buff.isDebuff then
                if buff.duration == -1 then
                    c = orange -- orange for permanent debuffs
                else
                    c = lerp(buff.duration, 5, 60, lightRed, red)
                end
            else
                if buff.duration == -1 then
                    c = lightBlue -- light blue for permanent buffs
                else
                    c = lerp(buff.duration, 5, 60, lightGreen, green)
                end
            end
            renderer:renderPixelIcon(vec2(rx, res.y - 65 + (i % 2) * 30), ColorRGB(c.x, c.y, c.z), buff.icon)
        end
        i = i + 1
    end
    renderer:display()
    -- render tooltip
    if hoveredBuffTooltip then
        hoveredBuffTooltip:draw(Mouse().position)
    end
end

function Buffs.onCraftSeatEntered(entityId, seat, playerIndex)
    if Player().index == playerIndex then
        invokeServerFunction("refreshData")
    end
end

-- API --
-- Returns all buffs as a table
function Buffs.getBuffs()
    local r = {}
    local e
    for _, buff in pairs(buffs) do
        e = {}
        for k, v in pairs(buff) do
            e[k] = v
        end
        r[#r+1] = e
    end
    return r
end

-- Buffs.getBuff(name [, type])
--[[ Returns specified buff info
name - Buff name
type - Optional (default: nil). 1 - BaseMultiplier; 2 - Multiplier; 3 - MultiplyableBias; 4 - AbsoluteBias; 5 - Buff; nil - any type ]]
function Buffs.getBuff(name, type)
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        return buffs[name]
    end
    for _, buff in pairs(buffs) do
        if buff.name == name then
            return buff
        end
    end
end


else -- onServer


local configOptions = {
  _version = {default = "0.1", comment = "Config version. Don't touch."},
  LogLevel = {default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."},
  UpdateInterval = { default = 1, min = 0.1, comment = "How precise system upgrade decay is (smaller = more precise)." }
}
local config, isModified = Azimuth.loadConfig("Buffs", configOptions)
if isModified then
    Azimuth.saveConfig("Buffs", config, configOptions)
end
local Log = Azimuth.logs("Buffs", config.LogLevel)

local data = {
  nextKey = 10000,
  freeKeys = {},
  buffs = {}
}
local pending = {} -- functions that modders tried to call before `restore`
local isReady -- immediately true if script was just added, otherwise false until `restore` function

local function getFreeKey(amount) -- Find available keys for stat bonuses
    -- single key
    if not amount then
        local key
        if #data.freeKeys > 0 then -- try to reuse old keys
            local length = #data.freeKeys
            key = data.freeKeys[length]
            data.freeKeys[length] = nil
            return key
        end
        key = data.nextKey
        if key == 11000 then return nil end -- ran out of keys
        data.nextKey = data.nextKey + 1
        return key
    end
    -- multiple keys
    local freeLen = #data.freeKeys
    local available = freeLen + (11000 - data.nextKey)
    if amount > available then return nil end -- ran out of keys
    local keys = {}

    local maxFree = math.min(freeLen, amount)
    amount = amount - maxFree
    for i = freeLen, 1 + (freeLen - maxFree), -1 do -- try to reuse old keys
        keys[#keys+1] = data.freeKeys[i]
        data.freeKeys[i] = nil
    end
    for i = 1, amount do
        keys[#keys+1] = data.nextKey
        data.nextKey = data.nextKey + 1
    end
    return keys
end

function Buffs.getUpdateInterval()
    return config.UpdateInterval
end

function Buffs.initialize()
    local entity = Entity()
    -- if script was just added, it will not have 
    isReady = entity:getValue("Buffs") == nil
    if isReady then
        entity:setValue("Buffs", true)
    end
    Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
end

function Buffs.onRemove()
    Log.Info("'%s': onRemove fired for some reason", Entity().index.string)
    -- in case something happens and script will be removed, reset 'Buffs'
    Entity():setValue("Buffs")
end

function Buffs.update(timePassed)
    local canFixEffects = true
    for name, buff in pairs(data.buffs) do
        if buff.duration ~= -1 then -- decay duration and remove buffs
            buff.duration = math.max(0, buff.duration - timePassed)
            if buff.duration == 0 then
                Buffs.removeBonus(name)
            end
        end
        -- check if entity should have any custom effects
        if data.fixEffects and canFixEffects and buff and buff.duration ~= 0 and buff.type == 5 then
            for _, effect in ipairs(buff.effects) do
                if effect.script then
                    canFixEffects = false
                    break
                end
            end
        end
    end
    if data.fixEffects and canFixEffects then -- some custom effect scripts weren't removed when needed, trying to fix this
        Log.Debug("Trying to remove old custom effects")
        local entity = Entity()
        local scripts = entity:getScripts()
        for index, path in pairs(scripts) do
            if string.find(path, "data/scripts/entity/buffs/", 1, true) then
                Log.Debug("Removing old effect script %i: %s", index, path)
                entity:removeScript(path)
            end
        end
        data.fixEffects = nil
    end
end

function Buffs.secure()
    return data
end

function Buffs.restore(_data)
    data = _data or {
      nextKey = 10000,
      freeKeys = {},
      buffs = {}
    }
    if not isReady then -- check for pending buffs
        isReady = true
        for _, v in ipairs(pending) do
            Buffs[v.func](unpack(v.args))
        end
        pending = nil
        Buffs.refreshData()
    end
end

function Buffs.refreshData() -- send data to clients
    if callingPlayer then
        local player = Player(callingPlayer)
        if player.craftIndex == Entity().index then
            invokeClientFunction(Player(callingPlayer), "receiveData", data.buffs)
        end
    else -- to all pilots
        local entity = Entity()
        if entity.hasPilot then
            for _, playerIndex in ipairs({entity:getPilotIndices()}) do
                invokeClientFunction(Player(playerIndex), "receiveData", data.buffs)
            end
        end
    end
end
callable(Buffs, "refreshData")

-- CALLBACKS --
function Buffs.onRestoredFromDisk(timePassed)
    for name, buff in pairs(data.buffs) do
        if buff.isAbsolute and buff.duration ~= -1 then
            buff.duration = math.max(0, buff.duration - timePassed)
            if buff.duration == 0 then
                Buffs.removeBonus(name)
            end
        end
    end
end

-- API --
-- BuffsHelper.addBuff(name, effects [, duration [, applyMode [, isAbsoluteDecay [, icon [, description [, color [, lowDurationColor]]]]]]])
--[[ Allows to add multiple bonuses within one buff/debuff.
Arguments:
* name - Buff name, can't contain '.'
* effects - Table where each element is a table with following properties:
  * type - Bonus type:
    1 - BaseMultiplier
    2 - Multiplier
    3 - MultiplyableBias
    4 - AbsoluteBias
  * stat - Value from StatsBonuses enum
  * value - Bonus value/factor
* duration - Duration in seconds (default: -1, permanent)
* applyMode - Mode:
  1 - Add: add if doesn't exist
  2 - AddOrRefresh: refresh duration or add buff if doesn't exist
  3 - AddOrCombine: combine duration or add buff if doesn't exist; can be used only if duration ~= -1
  4 - Refresh: refresh duration, DON'T add if doesn't exist
  5 - Combine: combine duration, DON'T add if doesn't exist; can be used only if duration ~= -1
* isAbsoluteDecay - If true, buff will decay even while sector with ship is unloaded (default: false)
* icon - Icon name. Icon should be in the "data/textures/icons/buffs/" folder.
* description - Buff description, long descriptions should be separated into lines with '\n'. I advise to register your descriptions in the "BuffsIntegration.lua" instead.
* descArgs - Table of arguments for description.
* color - Custom icon and title color, should be an int (example: 0xff0000ff - blue).
* lowDurationColor - Custom color that will be used in a gradient with previous color when there are < 60 seconds left.
Returns:
* true - Added/updated buff
* false - if applyMode == 1, buff already exists. If applyMode == 4 or 5, buff weren't updated because it doesn't exist
* nil - Error, look at second return value:
  0 - You tried to add buff before game called `restore` function. Your request will be processed but you will not be able to get return values.
  1 - Names can't contain '.'
  2 - Ran out of keys, can't add more than 1000 bonuses
Example:
Buffs.addBuff("Sturdy Build", {
  { type = BuffsHelper.Type.AbsoluteBias, stat = StatsBonuses.CargoHold, value = 50 },
  { type = BuffsHelper.Type.BaseMultiplier, stat = StatsBonuses.EnergyCapacity, value = 0.1 },
}, -1, BuffsHelper.ApplyMode.Add, false, "SturdyBuild", "Sturdy high-quality craft produced on a\nshipyard in sector ${sector}.", { sector = "(133:425)" })
]]
function Buffs._addBuff(name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "addBuff",
          args = {name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then -- can't use 'Combine' when duration is infinite
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "B_"..name

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local keysNeeded = 0
        for _, effect in ipairs(effects) do
            if not effect.script then -- only StatsBonuses need keys
                keysNeeded = keysNeeded + 1
            end
        end
        local keys = getFreeKey(keysNeeded)
        if not keys then return nil, 2 end -- can't add more than 1000 bonuses

        local entity = Entity()
        local k = 1
        local scripts, newScripts
        for _, effect in ipairs(effects) do
            if effect.script then
                if not effect.args then effect.args = {} end
                if not scripts then scripts = entity:getScripts() end
                entity:addScript("data/scripts/entity/buffs/"..effect.script..".lua", unpack(effect.args))
                newScripts = entity:getScripts()
                for j, _ in pairs(newScripts) do -- check the difference between old and new script indexes
                    if not scripts[j] then
                        effect.index = j
                        break
                    end
                end
                Log.Debug("effect.index: %i", effect.index or -1)
                scripts = newScripts
            else
                effect.key = keys[k]
                k = k + 1
                if effect.type == 1 then
                    entity:addKeyedBaseMultiplier(effect.stat, effect.key, effect.value)
                elseif effect.type == 2 then
                    entity:addKeyedMultiplier(effect.stat, effect.key, effect.value)
                elseif effect.type == 3 then
                    entity:addKeyedMultiplyableBias(effect.stat, effect.key, effect.value)
                else
                    entity:addKeyedAbsoluteBias(effect.stat, effect.key, effect.value)
                end
            end
        end
        data.buffs[fullname] = {
          name = name,
          effects = effects,
          duration = duration,
          isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          type = 5
        }
    else
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        buff.isAbsolute = isAbsoluteDecay and true or nil
        if icon then buff.icon = icon end
        if description then buff.desc = description end
        if color then buff.color = color end
    end
    Buffs.refreshData()
    return true
end

-- BuffsHelper.addBaseMultiplier(name, stat, value [, duration [, applyMode [, isAbsoluteDecay [, icon [, description [, color]]]]]])
--[[ Acts in a similar fashion to 'Entity():addBaseMultiplier'
Arguments:
* name - Buff name, can't contain '.'
* stat - Value from StatsBonuses enum
* value - Bonus value/factor
* duration - Duration in seconds (default: -1, permanent)
* applyMode - Mode:
  1 - Add: add if doesn't exist
  2 - AddOrRefresh: refresh duration or add buff if doesn't exist
  3 - AddOrCombine: combine duration or add buff if doesn't exist; can be used only if duration ~= -1
  4 - Refresh: refresh duration, DON'T add if doesn't exist
  5 - Combine: combine duration, DON'T add if doesn't exist; can be used only if duration ~= -1
* isAbsoluteDecay - If true, buff will decay even while sector with ship is unloaded (default: false)
* icon - Icon name. Icon should be in the "data/textures/icons/buffs/" folder.
* description - Buff description, long descriptions should be separated into lines with '\n'. I advise to register your descriptions in the "BuffsIntegration.lua" instead.
* descArgs - Table of arguments for description.
* color - Custom icon color, should be an int (example: 0xff0000ff - blue).
* lowDurationColor - Custom color that will be used in a gradient with previous color when there are < 60 seconds left.
Returns:
* true - Added/updated buff
* false - if applyMode == 1, buff already exists. If applyMode == 4 or 5, buff weren't updated because it doesn't exist
* nil - Error, look at second return value:
  0 - You tried to add buff before game called `restore` function. Your request will be processed but you will not be able to get return values.
  1 - Names can't contain '.'
  2 - Ran out of keys, can't add more than 1000 bonuses
]]
function Buffs._addBaseMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "addBaseMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "BM_"..name

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        data.buffs[fullname] = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          key = key,
          type = 1
        }
        Entity():addKeyedBaseMultiplier(stat, key, value)
    else
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        buff.isAbsolute = isAbsoluteDecay and true or nil
        if icon then buff.icon = icon end
        if description then buff.desc = description end
        if color then buff.color = color end
    end
    Buffs.refreshData()
    return true
end

function Buffs._addMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "addMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "M_"..name

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        data.buffs[fullname] = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          key = key,
          type = 2
        }
        Entity():addKeyedMultiplier(stat, key, value)
    else
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        buff.isAbsolute = isAbsoluteDecay and true or nil
        if icon then buff.icon = icon end
        if description then buff.desc = description end
        if color then buff.color = color end
    end
    Buffs.refreshData()
    return true
end

function Buffs._addMultiplyableBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "addMultiplyableBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "MB_"..name

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        data.buffs[fullname] = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          key = key,
          type = 3
        }
        Entity():addKeyedMultiplyableBias(stat, key, value)
    else
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        buff.isAbsolute = isAbsoluteDecay and true or nil
        if icon then buff.icon = icon end
        if description then buff.desc = description end
        if color then buff.color = color end
    end
    Buffs.refreshData()
    return true
end

function Buffs._addAbsoluteBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "addAbsoluteBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "AB_"..name

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        data.buffs[fullname] = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          key = key,
          type = 4
        }
        Entity():addKeyedAbsoluteBias(stat, key, value)
    else
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        buff.isAbsolute = isAbsoluteDecay and true or nil
        if icon then buff.icon = icon end
        if description then buff.desc = description end
        if color then buff.color = color end
    end
    Buffs.refreshData()
    return true
end

--[[ Removes buff
Returns:
* true - success
* false - buff doesn't exist
* nil - error, look at the second return value:
  0 - You called the function before game called `restore`. Your request will be processed later and you will not be able to get return values.
  1 - names can't contain '.'
]]
function Buffs.removeBuff(name)
    return Buffs.removeBonus("B_"..name)
end

function Buffs.removeBaseMultiplier(name)
    return Buffs.removeBonus("BM_"..name)
end

function Buffs.removeMultiplier(name)
    return Buffs.removeBonus("M_"..name)
end

function Buffs.removeMultiplyableBias(name)
    return Buffs.removeBonus("MB_"..name)
end

function Buffs.removeAbsoluteBias(name)
    return Buffs.removeBonus("AB_"..name)
end

function Buffs.removeBonus(fullname)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "removeBonus",
          args = {fullname}
        }
        return nil, 0
    end
    if string.find(fullname, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    local buff = data.buffs[fullname]
    if not buff then return false end -- can't find
    if buff.type == 5 then -- remove all bonuses
        local entity = Entity()
        local scripts, script, effectScript
        for _, effect in ipairs(buff.effects) do
            if effect.script then
                if effect.index then
                    if not scripts then scripts = entity:getScripts() end
                    effectScript = "data/scripts/entity/buffs/"..effect.script..".lua"
                    script = scripts[effect.index]
                    if script and string.find(script, effectScript, 1, true) then
                        entity:removeScript(effect.index)
                        Log.Debug("Removing buff script: %i", effect.index)
                    else
                        Log.Error("Couldn't remove buff script '%i', paths don't match: '%s' ~= '%s' - will be automatically fixed when possible", effect.index, effectScript, script or "")
                        data.fixEffects = true
                    end
                end
            else
                entity:removeBonus(effect.key)
                data.freeKeys[#data.freeKeys+1] = effect.key
            end
        end
    else
        Entity():removeBonus(buff.key)
        data.freeKeys[#data.freeKeys+1] = buff.key
    end
    data.buffs[fullname] = nil
    Buffs.refreshData()
    return true
end

-- Returns all buffs as a table. If called before `restore`, will return empty table.
function Buffs.getBuffs()
    if not isReady then return {}, 1 end
    local r = {}
    local e
    for _, buff in pairs(data.buffs) do
        r[#r+1] = table.deepcopy(buff)
    end
    return r
end

-- Buffs.getBuff(name [, type])
--[[ Returns specified buff info
name - Buff name
type - Optional (default: nil). 1 - BaseMultiplier; 2 - Multiplier; 3 - MultiplyableBias; 4 - AbsoluteBias; 5 - Buff; nil - any type.
Returns:
* table - buff table
* nil - Error, look at 2 return value:
  0 - You called the function before game called `restore`, no data can be received
  1 - names can't contain '.'
]]
function Buffs.getBuff(name, type)
    if not isReady then return nil, 0 end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        return data.buffs[name]
    end
    for _, buff in pairs(data.buffs) do
        if buff.name == name then
            return buff
        end
    end
end


end