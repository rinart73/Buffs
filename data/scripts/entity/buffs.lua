package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
include("stringutility")
local Azimuth = include("azimuthlib-basic")
local BuffsHelper = include("BuffsHelper")

-- namespace Buffs
Buffs = {}

local buffPrefixes = {"BM_", "M_", "MB_", "AB_", "_B"}
local statLabels = {}
local buffDescriptions, Config, Log, stats, uiStats, statNames, customEffects, buffs, buffsCount, hoveredBuffTooltip, prevHoveredName, distanceString, post0_25_2
local data, pending, isReady

if onClient() then


include("azimuthlib-uiproportionalsplitter")
buffDescriptions = include("BuffsIntegration")

local configOptions = {
  _version = {default = "0.1", comment = "Config version. Don't touch."},
  LogLevel = {default = 2, min = 0, max = 4, format = "floor", comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."},
}
local isModified
Config, isModified = Azimuth.loadConfig("Buffs", configOptions)
if isModified then
    Azimuth.saveConfig("Buffs", Config, configOptions)
end
Log = Azimuth.logs("Buffs", Config.LogLevel)


stats = {
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
statNames = {
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
    value = 500 -- 5km, check
  },
  ScannerMaterialReach = {
    name = "Material Scanner Range"%_t,
    value = 500 -- 5km, check
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
    value = 1 -- check
  },
  UnarmedTurrets = {
    name = "Unarmed Turret Slots"%_t,
    value = 1 -- check
  },
  ArmedTurrets = {
    name = "Armed Turret Slots"%_t,
    value = 1 -- check
  },
  CargoHold = {
    name = "Cargo Hold"%_t,
    stat = "cargoHold"
  },
  LootCollectionRange = {
    name = "Loot Collection Range"%_t,
    value = 100 -- from tests, not sure
  },
  TransporterRange = {
    name = "Docking Distance"%_t,
    value = 0
  },
  DefenseWeapons = {
    name = "Defense Weapons"%_t,
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
customEffects = {}
for _, v in pairs(BuffsHelper.Custom) do
    customEffects[v.script] = v
end
buffs = {}
buffsCount = 0
distanceString = "+${distance} km"%_t
distanceString = distanceString:sub(2)

local version = GameVersion()
post0_25_2 = version.minor > 25 or (version.minor == 25 and version.patch == 2)

function Buffs.getBonusStatString(type, stat, value, noSign) -- create correct description of buff effect
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
            valueStr = distanceString % {distance = round(value / 100, 2)} -- to km
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

function Buffs.getIcon()
    return "data/textures/icons/blockstats.png"
end

function Buffs.getUpdateInterval()
    return 0.2
end

function Buffs.initialize()
    uiStats = stats -- display order
    -- correct stats indexes
    local correctedStats = {}
    for _, key in ipairs(stats) do
        correctedStats[StatsBonuses[key]] = key
    end
    stats = correctedStats

    Player():registerCallback("onPostRenderHud", "onRenderHud")
    Entity():registerCallback("onCraftSeatEntered", "onCraftSeatEntered")

    if Player().craftIndex == Entity().index then
        invokeServerFunction("refreshData")
    end
end

function Buffs.interactionPossible(playerIndex, option)
    local factionIndex = Entity().factionIndex
    if factionIndex == playerIndex or factionIndex == Player().allianceIndex then
        return true
    end

    return false
end

function Buffs.initUI()
    local res = getResolution()
    local size = vec2(700, 510)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Craft Stats"%_t)
    window.caption = "Craft Stats"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local hpartitions = UIHorizontalProportionalSplitter(Rect(size), 10, 10, {20, 0.5})
    
    local partitions = UIVerticalProportionalSplitter(hpartitions[1], 10, {10, 25, 3, 0}, {0.55, 0.225, 0.225})
    window:createLabel(partitions[1], "Stat"%_t, 13)
    window:createLabel(partitions[2], "Base value"%_t, 13)
    window:createLabel(partitions[3], "Result"%_t, 13)

    local lister = UIVerticalLister(hpartitions[2], 10, 10)
    lister.marginLeft = 0
    lister.marginRight = 35

    local frame = window:createScrollFrame(hpartitions[2])
    frame.scrollSpeed = 40

    local index = 0
    local rect, nameLabel, baseValueLabel, resultingValueLabel, pair
    for _, bonus in pairs(uiStats) do
        pair = statNames[bonus]
        if pair.value or pair.stat or pair.crew or pair.func then -- don't show stat if there is no way to get base value
            rect = lister:placeCenter(vec2(lister.inner.width, 28))
            partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
            nameLabel = frame:createLabel(partitions[1], pair.name, 14)
            nameLabel.wordBreak = true
            baseValueLabel = frame:createLabel(partitions[2], "", 14)
            resultingValueLabel = frame:createLabel(partitions[3], "", 14)

            if index % 2 == 0 then
                nameLabel.color = ColorInt(0xff797979)
                baseValueLabel.color = ColorInt(0xff696969)
                resultingValueLabel.color = ColorInt(0xff696969)
            end

            statLabels[#statLabels+1] = {
              baseValue = baseValueLabel,
              resultingValue = resultingValueLabel,
              bonus = bonus
            }
            index = index + 1
        end
    end
    uiStats = nil
end

function Buffs.onShowWindow()
    local entity = Entity()
    local crew = entity.crew
    local planStats = entity:getPlan():getStats()
    local value, bonus, bonusId
    for _, group in ipairs(statLabels) do
        bonus = statNames[group.bonus]
        bonusId = StatsBonuses[group.bonus]
        if bonus.value then
            value = bonus.value
        elseif bonus.stat then
            value = planStats[bonus.stat]
        elseif bonus.crew then
            value = crew[bonus.crew]
        elseif bonus.func then
            value = bonus.func(planStats)
        else
            value = nil
        end
        if value ~= nil then
            group.baseValue.caption = Buffs.getBonusStatString(4, bonusId, value, true)
        else
            group.baseValue.caption = "?"
            value = 1
        end

        value = entity:getBoostedValue(bonusId, value)
        group.resultingValue.caption = Buffs.getBonusStatString(4, bonusId, value, true)
    end
end

local shield = 0
function Buffs.update(timePassed)
    local player = Player()
    if player.craftIndex ~= Entity().index then return end
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
    local noClientUpdate = false
    if post0_25_2 then
        if player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact then
            noClientUpdate = true
        end
    end
    for _, buff in ipairs(buffs) do
        -- decay buffs
        if buff.duration ~= -1 then
            buff.redraw = math.floor(buff.duration)
            buff.duration = math.max(0, buff.duration - timePassed)
            buff.redraw = buff.redraw - math.floor(buff.duration)
        end
        -- check mouse hover
        if not noClientUpdate and not found then
            rx = res.x / 2 + 270 + math.floor(i / 2) * 30
            ry = res.y - 65 + (i % 2) * 30

            if mousePos.x >= rx and mousePos.x <= rx + 25 and mousePos.y >= ry and mousePos.y <= ry + 25 then
                found = true
                if buff.redraw == 1 or prevHoveredName ~= buff.fullname then
                    prevHoveredName = buff.fullname

                    local tooltip = Tooltip()
                    local line = TooltipLine(20, 15)
                    line.ltext = buff.name
                    if buff.type == 5 then
                        line.lcolor = buff.color and buff.color or white
                    else
                        line.lcolor = buff.isDebuff and red or green
                    end
                    line.rtext = buff.duration ~= -1 and math.floor(buff.duration).."s /* Unit for seconds */"%_t or "Permanent"%_t
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
                                line.ltext = statNames[stats[effect.stat]].name
                                line.rtext = Buffs.getBonusStatString(effect.type, effect.stat, effect.value)
                            end
                            tooltip:addLine(line)
                        end
                    else
                        line = TooltipLine(16, 13)
                        line.ltext = statNames[stats[buff.stat]].name
                        line.rtext = Buffs.getBonusStatString(buff.type, buff.stat, buff.value)
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
    --buffs = _buffs
    local newbuffs = {}
    for fullname, buff in pairs(_buffs) do
        buff.fullname = fullname
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
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or stats[buff.stat]) .. ".png"
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
        newbuffs[buffsCount] = buff
    end
    -- sort buffs by priority
    table.sort(newbuffs, function(a, b)
        local aprio = a.prio or 0
        local bprio = b.prio or 0
        if aprio > bprio then
            return true
        elseif aprio == bprio then
            return a.name < b.name
        end
    end)
    buffs = newbuffs
end

-- CALLBACKS --
function Buffs.onRenderHud()
    local player = Player()
    if player.craftIndex ~= Entity().index then return end
    if buffsCount == 0 then return end
    if post0_25_2 then
        if player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact then
            return
        end
    end

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
    for _, buff in ipairs(buffs) do
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
local isModified
Config, isModified = Azimuth.loadConfig("Buffs", configOptions)
if isModified then
    Azimuth.saveConfig("Buffs", Config, configOptions)
end
Log = Azimuth.logs("Buffs", Config.LogLevel)

data = {
  nextKey = 10000,
  freeKeys = {},
  buffs = {}
}
pending = {} -- functions that modders tried to call before `restore`
-- local isReady -- immediately true if script was just added, otherwise false until `restore` function

function Buffs.getFreeKey(amount) -- Find available keys for stat bonuses
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
    return Config.UpdateInterval
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
    local entity = Entity()
    -- save energy and shield
    data.shield = entity.shieldDurability
    if entity:hasComponent(ComponentType.EnergySystem) then
        data.energy = EnergySystem(entity).energy
    else
        data.energy = nil
    end
    Log.Debug("Secure: %s (%s): shield %s, energy %s", tostring(entity.name), entity.index.string, tostring(data.shield), tostring(data.energy))

    return data
end

function Buffs.restore(_data)
    local entity = Entity()
    Log.Debug("Restore: %s (%s)", tostring(entity.name), entity.index.string)
    data = _data or {
      nextKey = 10000,
      freeKeys = {},
      buffs = {}
    }
    if not isReady then -- check for pending buffs
        -- reapply old buffs
        for fullname, buff in pairs(data.buffs) do
            if buff.type == 1 then
                entity:addKeyedBaseMultiplier(buff.stat, buff.key, buff.value)
            elseif buff.type == 2 then
                entity:addKeyedMultiplier(buff.stat, buff.key, buff.value)
            elseif buff.type == 3 then
                entity:addKeyedMultiplyableBias(buff.stat, buff.key, buff.value)
            elseif buff.type == 4 then
                entity:addKeyedAbsoluteBias(buff.stat, buff.key, buff.value)
            elseif buff.type == 5 then
                for _, effect in ipairs(buff.effects) do
                    if effect.type == 1 then
                        entity:addKeyedBaseMultiplier(effect.stat, effect.key, effect.value)
                    elseif effect.type == 2 then
                        entity:addKeyedMultiplier(effect.stat, effect.key, effect.value)
                    elseif effect.type == 3 then
                        entity:addKeyedMultiplyableBias(effect.stat, effect.key, effect.value)
                    elseif effect.type == 4 then
                        entity:addKeyedAbsoluteBias(effect.stat, effect.key, effect.value)
                    end
                end
            end
        end
        -- restore shield and energy
        deferredCallback(0.25, "deferredRestore", data.shield, data.energy)
        -- apply pending buffs
        isReady = true
        for _, v in ipairs(pending) do
            Buffs[v.func](unpack(v.args))
        end
        pending = nil
        Buffs.refreshData()
    end
end

function Buffs.deferredRestore(shield, energy)
    local entity = Entity()
    Log.Debug("dataShield: %s, shield: %s, maxShield: %s", tostring(shield), tostring(entity.shieldDurability), tostring(entity.shieldMaxDurability))
    if shield and entity.shieldMaxDurability then
        if shield > entity.shieldDurability then
            entity.shieldDurability = math.min(shield, entity.shieldMaxDurability)
        end
    end
    Log.Debug("dataEnergy: %s", tostring(energy))
    if energy and entity:hasComponent(ComponentType.EnergySystem) then
        local energySystem = EnergySystem(entity)
        Log.Debug("energy: %s, capacity: %s", tostring(energySystem.energy), tostring(energySystem.capacity))
        if energy > energySystem.energy then
            energySystem.energy = math.min(energy, energySystem.capacity)
        end
    end
end

function Buffs.refreshData() -- send data to clients
    if callingPlayer then
        local player = Player(callingPlayer)
        if player.craftIndex == Entity().index then
            invokeClientFunction(Player(callingPlayer), "receiveData", Buffs.prepareClientBuffs())
        end
    else -- to all pilots
        local entity = Entity()
        if entity.hasPilot then
            local clientBuffs = Buffs.prepareClientBuffs()
            for _, playerIndex in ipairs({entity:getPilotIndices()}) do
                invokeClientFunction(Player(playerIndex), "receiveData", clientBuffs)
            end
        end
    end
end
callable(Buffs, "refreshData")

function Buffs.prepareClientBuffs()
    local clientBuffs = {}
    for fullname, buff in pairs(data.buffs) do
        if buff.prio ~= -1000 then -- don't send hidden buffs
            clientBuffs[fullname] = buff
        end
    end
    return clientBuffs
end

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
* name - Buff name, can't contain '.'. If it starts with '_', it's a hidden buff that will not be sent to client side.
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
* priority (number) - Display priority, higher value = earlier in the list. If '-1000', a buff will not be sent to client.
Returns:
* true - Added/updated buff
* false - if applyMode == 1, buff already exists. If applyMode == 4 or 5, buff weren't updated because it doesn't exist
* nil - Error, look at second return value:
  0 - You tried to add buff before game called `restore` function. Your request will be processed but you will not be able to get return values.
  1 - Names can't contain '.'
  2 - Ran out of keys, can't add more than 1000 bonuses
  11 - The call failed because the entity with the specified index does not exist or has no scripting component.
  12 - The call failed because it came from another sector than the entity is in.
  13 - The call failed because the given script was not found in the entity.
  14 - The call failed because the given function was not found in the script.
Example:
Buffs.addBuff("Sturdy Build", {
  { type = BuffsHelper.Type.AbsoluteBias, stat = StatsBonuses.CargoHold, value = 50 },
  { type = BuffsHelper.Type.BaseMultiplier, stat = StatsBonuses.EnergyCapacity, value = 0.1 },
}, -1, BuffsHelper.ApplyMode.Add, false, "SturdyBuild", "Sturdy high-quality craft produced on a\nshipyard in sector ${sector}.", { sector = "(133:425)" })
]]
function Buffs._addBuff(name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBuff",
          args = {name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
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
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

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
        local keys = Buffs.getFreeKey(keysNeeded)
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
          prio = priority,
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
* name - Buff name, can't contain '.'. If it starts with '_', it's a hidden buff that will not be sent to client side.
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
* priority (number) - Display priority, higher value = earlier in the list. If -1000, a buff will not be sent to client.
Returns:
* true - Added/updated buff
* false - if applyMode == 1, buff already exists. If applyMode == 4 or 5, buff weren't updated because it doesn't exist
* nil - Error, look at second return value:
  0 - You tried to add buff before game called `restore` function. Your request will be processed but you will not be able to get return values.
  1 - Names can't contain '.'
  2 - Ran out of keys, can't add more than 1000 bonuses
  11 - The call failed because the entity with the specified index does not exist or has no scripting component.
  12 - The call failed because it came from another sector than the entity is in.
  13 - The call failed because the given script was not found in the entity.
  14 - The call failed because the given function was not found in the script.
]]
function Buffs._addBaseMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBaseMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
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
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = Buffs.getFreeKey()
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
          prio = priority,
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

function Buffs._addMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
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
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = Buffs.getFreeKey()
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
          prio = priority,
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

function Buffs._addMultiplyableBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplyableBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
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
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = Buffs.getFreeKey()
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
          prio = priority,
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

function Buffs._addAbsoluteBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addAbsoluteBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
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
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    if not buff then
        local key = Buffs.getFreeKey()
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
          prio = priority,
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