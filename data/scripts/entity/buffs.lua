package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
local Azimuth, Config, Log = unpack(include("buffsinit"))
local Helper = include("BuffsHelper")

-- namespace BuffsMod
BuffsMod = {}

local buffPrefixes = {"BM_", "M_", "MB_", "AB_", "_B"} -- client/server
local callbacks = {} -- client/server
local debugName -- client/server
local statLabels = {} -- client UI
local buffDescriptions, buffs, buffsCount, iconsRenderer, hoveredBuffTooltip, prevHoveredName -- client
local data, pending, isReady, isFirstLaunch, savedEntity -- server


if onClient() then


include("azimuthlib-uiproportionalsplitter")
buffDescriptions = include("BuffsIntegration")

-- PREDEFINED --

function BuffsMod.getUpdateInterval()
    return 0.2
end

function BuffsMod.initialize()
    buffs = {}
    buffsCount = 0

    Player():registerCallback("onPostRenderHud", "onPostRenderHud")
    local entity = Entity()
    debugName = string.format("%s(%s)", entity.name or entity.title, entity.index.string)
    entity:registerCallback("onCraftSeatEntered", "onCraftSeatEntered")

    if Player().craftIndex == entity.index then
        invokeServerFunction("refreshData")
    end
end

function BuffsMod.updateClient() -- Otherwise updateParallelSelf doesn't work?!
end

function BuffsMod.updateParallelSelf(timePassed)
    local player = Player()
    local entity = Entity()
    if player.craftIndex ~= Entity().index then return end
    if buffsCount == 0 then return end

    local res, mousePos
    local noClientUpdate = false
    if Config.HideShipIconsOverlay or (player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact) then
        noClientUpdate = true
    else
        iconsRenderer = UIRenderer()
        res = getResolution()
        mousePos = Mouse().position
    end
    local found = false -- if at least one buff was hovered
    local i = 0 -- buff number, affects position
    for _, buff in ipairs(buffs) do
        -- decay buffs
        if buff.duration ~= -1 then
            buff.redraw = math.floor(buff.duration)
            buff.duration = math.max(0, buff.duration - timePassed)
            buff.redraw = buff.redraw - math.floor(buff.duration)
        end
        if not noClientUpdate then
            local rx = res.x / 2 + 270 + math.floor(i / 2) * 30
            local ry = res.y - 65 + (i % 2) * 30

            -- check mouse hover
            if not found and mousePos.x >= rx and mousePos.x <= rx + 25 and mousePos.y >= ry and mousePos.y <= ry + 25 then
                found = true
                if buff.redraw == 1 or prevHoveredName ~= buff.fullname then
                    prevHoveredName = buff.fullname
                    hoveredBuffTooltip = TooltipRenderer(Helper.createBuffTooltip(false, buff))
                end
            end
            -- redraw icons 5 times per second instead of FPS time per second
            if rx + 35 <= res.x then
                iconsRenderer:renderPixelIcon(vec2(rx, ry), Helper.getBuffColor(buff), buff.icon)
            end
        end
        i = i + 1
    end
    if not found then
        prevHoveredName = nil
        hoveredBuffTooltip = nil
    end
end

-- CALLBACKS --

function BuffsMod.onCraftSeatEntered(entityId, seat, playerIndex)
    if Player().index == playerIndex then
        invokeServerFunction("refreshData")

        local status, value = Player():invokeFunction("buffs.lua", "getHideShipIconsOverlay")
        if status ~= 0 then
            value = false
        end
        Config.HideShipIconsOverlay = value
    end
end

function BuffsMod.onPostRenderHud(state)
    if buffsCount == 0 or Config.HideShipIconsOverlay then return end
    local player = Player()
    if player.craftIndex ~= Entity().index then return end
    if state ~= PlayerStateType.Fly and state ~= PlayerStateType.Interact then return end
    if iconsRenderer then
        iconsRenderer:display()
    end
    if hoveredBuffTooltip then
        hoveredBuffTooltip:draw(Mouse().position)
    end
end

-- CALLABLE --

function BuffsMod.receiveData(_buffs)
    Log:Debug("(%s) receiveData: %s", debugName, _buffs)
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
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or Helper.BonusNameByIndex[buff.stat]) .. ".png"
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

-- FUNCTIONS --

function BuffsMod.setHideShipIconsOverlay(value)
    Config.HideShipIconsOverlay = value
end

-- API --

function BuffsMod.getBuffs()
    return buffs and table.deepcopy(buffs) or {}
end

function BuffsMod.getBuff(name, type)
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        local buff = buffs[name]
        return buff and table.deepcopy(buff) or nil
    end
    for _, buff in pairs(buffs) do
        if buff.name == name then
            return table.deepcopy(buff)
        end
    end
end


else -- onServer


data = {
  nextKey = 10000,
  freeKeys = {},
  buffs = {}
}
pending = {} -- functions that modders tried to call before `restore`
-- local isReady -- immediately true if script was just added, otherwise false until `restore` function

-- PREDEFINED --

function BuffsMod.getUpdateInterval()
    return Entity().aiOwned and Config.NPCUpdateInterval or Config.UpdateInterval
end

function BuffsMod.initialize()
    local entity = Entity()
    savedEntity = entity
    debugName = string.format("%s(%s)", entity.name or entity.title, entity.index.string)
    -- if script was just added, it will not have 
    isReady = entity:getValue("Buffs") == nil
    if isReady then
        isFirstLaunch = true
        entity:setValue("Buffs", true)
        entity:sendCallback("onBuffsReady", entity.index, {}, true, false)
    end
    entity:registerCallback("onSectorEntered", "onSectorEntered")
    entity:registerCallback("onCraftSeatEntered", "onCraftSeatEntered")
    entity:registerCallback("onCraftSeatLeft", "onCraftSeatLeft")
    Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
end

function BuffsMod.update(timePassed) -- Can't use updateParallelSelf because custom callbacks crash the server
    local canFixEffects = true
    for name, buff in pairs(data.buffs) do
        if buff.duration ~= -1 then -- decay duration and remove buffs
            buff.duration = math.max(0, buff.duration - timePassed)
            if buff.duration == 0 then
                BuffsMod.removeBuffWithType(name)
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
        Log:Info("(%s) trying to remove old custom effects", debugName)
        local entity = Entity()
        local scripts = entity:getScripts()
        for index, path in pairs(scripts) do
            if string.find(path, "data/scripts/entity/buffs/", 1, true) then
                Log:Debug("(%s) removing old effect script %i: %s", debugName, index, path)
                entity:removeScript(path)
            end
        end
        data.fixEffects = nil
    end
end

function BuffsMod.secure()
    -- attempting to fix an error
    if not savedEntity or not valid(savedEntity) then
        Log:Info("(%s) secure - entity is nil or invalid", debugName)
        data.shield = nil
        data.energy = nil
        return data
    end
    -- save energy and shield
    data.shield = savedEntity.shieldDurability
    if savedEntity:hasComponent(ComponentType.EnergySystem) then
        data.energy = EnergySystem(savedEntity).energy
    else
        data.energy = nil
    end
    Log:Debug("(%s) Secure: shield %s, energy %s", debugName, tostring(data.shield), tostring(data.energy))

    return data
end

function BuffsMod.restore(_data)
    local entity = Entity()
    Log:Debug("(%s) Restore", debugName)
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
        local absoluteIgnore = {} -- a fix for pending absolute-duration buffs
        for _, v in ipairs(pending) do
            absoluteIgnore[v.args[1]] = true
            BuffsMod[v.func](unpack(v.args))
        end
        pending = absoluteIgnore
        entity:sendCallback("onBuffsReady", entity.index, table.deepcopy(data.buffs), false, false)
        BuffsMod.refreshData()
    end
end

function BuffsMod.onRemove()
    Log:Info("(%s) onRemove fired for some reason", debugName)
    -- in case something happens and script will be removed, reset 'Buffs'
    Entity():setValue("Buffs")
end

-- CALLABLE --

function BuffsMod.refreshData() -- send data to clients
    if callingPlayer then
        local player = Player(callingPlayer)
        if player.craftIndex == Entity().index then
            invokeClientFunction(player, "receiveData", BuffsMod.prepareClientBuffs())
        end
    else -- to all pilots
        local entity = Entity()
        if entity.hasPilot then
            local clientBuffs = BuffsMod.prepareClientBuffs()
            for _, playerIndex in ipairs({entity:getPilotIndices()}) do
                invokeClientFunction(Player(playerIndex), "receiveData", clientBuffs)
            end
        end
    end
end
callable(BuffsMod, "refreshData")

-- CALLBACKS --

function BuffsMod.onSectorEntered()
    savedEntity = Entity()
end

function BuffsMod.onRestoredFromDisk(timePassed)
    if not pending then pending = {} end
    for fullname, buff in pairs(data.buffs) do
        if buff.isAbsolute and buff.duration ~= -1 and not pending[buff.name] then
            buff.duration = math.max(0, buff.duration - timePassed)
            if buff.duration == 0 then
                BuffsMod.removeBuffWithType(fullname)
            end
        end
    end
end

function BuffsMod.onCraftSeatEntered(entityId, seat, playerIndex) -- add tied-buffs
    if Entity().index == entityId and seat == 0 then
        local player = Player(playerIndex)
        local playerBuffs = Helper.getBuffs(player)
        if not playerBuffs then
            Log:Error("(%s) Player '%s'(%i) buffs is nil", debugName, player.name, playerIndex)
        else
            local funcs = {"_addBaseMultiplier", "_addMultiplier", "_addMultiplyableBias", "_addAbsoluteBias"}
            for _, buff in ipairs(playerBuffs) do
                if buff.type ~= 5 then -- StatsBonuses
                    Log:Debug("(%s) Adding tied buff '%s' from player '%s'(%i)", debugName, buff.name, player.name, playerIndex)
                    BuffsMod[funcs[buff.type]](buff.name, buff.stat, buff.value, buff.duration, Helper.Mode.AddOrRefresh, nil, buff.icon, buff.desc, buff.descArgs, buff.color, buff.lowColor, buff.prio, playerIndex)
                elseif #buff.shipEffects > 0 then
                    Log:Debug("(%s) Adding tied buff '%s' from player '%s'(%i)", debugName, buff.name, player.name, playerIndex)
                    BuffsMod._addBuff(buff.name, buff.shipEffects, buff.duration, Helper.Mode.AddOrRefresh, nil, buff.icon, buff.desc, buff.descArgs, buff.color, buff.lowColor, buff.prio, playerIndex)
                end
            end
        end
    end
end

function BuffsMod.onCraftSeatLeft(entityId, seat, playerIndex) -- remove tied buffs
    if Entity().index == entityId and seat == 0 then
        for fullname, buff in pairs(data.buffs) do
            if buff.player == playerIndex then
                Log:Debug("(%s) Removing tied player %i buff '%s'", debugName, playerIndex, fullname)
                BuffsMod.removeBuffWithType(fullname)
            end
        end
    end
end

-- FUNCTIONS --

function BuffsMod.getFreeKey(amount) -- Find available keys for stat bonuses
    -- single key
    if not amount then
        local key
        local length = #data.freeKeys
        if length > 0 then -- try to reuse old keys
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

function BuffsMod.deferredRestore(shield, energy)
    local entity = Entity()
    Log:Debug("(%s) dataShield: %s, shield: %s, maxShield: %s", debugName, tostring(shield), tostring(entity.shieldDurability), tostring(entity.shieldMaxDurability))
    if shield and entity.shieldMaxDurability then
        if shield > entity.shieldDurability then
            entity.shieldDurability = math.min(shield, entity.shieldMaxDurability)
        end
    end
    Log:Debug("(%s) dataEnergy: %s", debugName, tostring(energy))
    if energy and entity:hasComponent(ComponentType.EnergySystem) then
        local energySystem = EnergySystem(entity)
        Log:Debug("(%s) energy: %s, capacity: %s", debugName, tostring(energySystem.energy), tostring(energySystem.capacity))
        if energy > energySystem.energy then
            energySystem.energy = math.min(energy, energySystem.capacity)
        end
    end
end

function BuffsMod.prepareClientBuffs()
    local clientBuffs = {}
    for fullname, buff in pairs(data.buffs) do
        if buff.prio ~= -1000 then -- don't send hidden buffs
            clientBuffs[fullname] = buff
        end
    end
    return clientBuffs
end

-- NEVER call this function via 'BuffsMod._addBuff'. Use 'BuffsHelper.addBuff' from the BuffsHelper.lua
function BuffsMod._addBuff(name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBuff",
          args = {name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex}
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

    local entity = Entity()
    if _playerIndex then -- it's a tied buff
        local player = Player(_playerIndex)
        if player.craft.index ~= entity.index then return nil, 9 end
    end

    if not buff then
        local keysNeeded = 0
        for _, effect in ipairs(effects) do
            if effect.type then -- only StatsBonuses need keys
                keysNeeded = keysNeeded + 1
            end
        end
        local keys = BuffsMod.getFreeKey(keysNeeded)
        if not keys then return nil, 2 end -- can't add more than 1000 bonuses

        local k = 1
        local scripts
        for i, effect in ipairs(effects) do
            if effect[1] then -- support for a short-hand for vanilla stats
                effect = { type = effect[1], stat = effect[2], value = effect[3] }
                effects[i] = effect
            end
            if effect.script then -- custom entity script
                if not effect.args then effect.args = {} end
                if not scripts then scripts = entity:getScripts() end
                entity:addScript("data/scripts/entity/buffs/"..effect.script..".lua", unpack(effect.args))
                local newScripts = entity:getScripts()
                for j, _ in pairs(newScripts) do -- check the difference between old and new script indexes
                    if not scripts[j] then
                        effect.index = j
                        break
                    end
                end
                Log:Debug("(%s) _addBuff, script effect.index: %i", debugName, effect.index or -1)
                scripts = newScripts
            elseif effect.customStat and effect.target ~= Helper.Target.Player then -- custom stat
                local entityStat = Helper.Stats[effect.customStat]
                if entityStat then
                    entityStat.onApply(nil, entity, unpack(effect.args))
                end
            elseif effect.type then -- vanilla StatsBonuses
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
        buff = {
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
          type = 5,
          player = _playerIndex
        }
        data.buffs[fullname] = buff
        entity:sendCallback("onBuffApplied", entity.index, 5, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- allow to modify other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        entity:sendCallback("onBuffApplied", entity.index, 5, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addBaseMultiplier'. Use 'BuffsHelper.addBaseMultiplier' from the BuffsHelper.lua
function BuffsMod._addBaseMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBaseMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex}
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

    local entity = Entity()
    if _playerIndex then -- it's a tied buff
        local player = Player(_playerIndex)
        if player.craft.index ~= entity.index then return nil, 9 end
    end

    if not buff then
        local key = BuffsMod.getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        entity:addKeyedBaseMultiplier(stat, key, value)
        buff = {
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
          type = 1,
          player = _playerIndex
        }
        data.buffs[fullname] = buff
        entity:sendCallback("onBuffApplied", entity.index, 1, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        entity:sendCallback("onBuffApplied", entity.index, 1, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addMultiplier'. Use 'BuffsHelper.addMultiplier' from the BuffsHelper.lua
function BuffsMod._addMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex}
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

    local entity = Entity()
    if _playerIndex then -- it's a tied buff
        local player = Player(_playerIndex)
        if player.craft.index ~= entity.index then return nil, 9 end
    end

    if not buff then
        local key = BuffsMod.getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        entity:addKeyedMultiplier(stat, key, value)
        buff = {
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
          type = 2,
          player = _playerIndex
        }
        data.buffs[fullname] = buff
        entity:sendCallback("onBuffApplied", entity.index, 2, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        entity:sendCallback("onBuffApplied", entity.index, 2, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addMultiplyableBias'. Use 'BuffsHelper.addMultiplyableBias' from the BuffsHelper.lua
function BuffsMod._addMultiplyableBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplyableBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex}
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

    local entity = Entity()
    if _playerIndex then -- it's a tied buff
        local player = Player(_playerIndex)
        if player.craft.index ~= entity.index then return nil, 9 end
    end

    if not buff then
        local key = BuffsMod.getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        entity:addKeyedMultiplyableBias(stat, key, value)
        buff = {
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
          type = 3,
          player = _playerIndex
        }
        data.buffs[fullname] = buff
        entity:sendCallback("onBuffApplied", entity.index, 3, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        entity:sendCallback("onBuffApplied", entity.index, 3, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addAbsoluteBias'. Use 'BuffsHelper.addAbsoluteBias' from the BuffsHelper.lua
function BuffsMod._addAbsoluteBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addAbsoluteBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority, _playerIndex}
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

    local entity = Entity()
    if _playerIndex then -- it's a tied buff
        local player = Player(_playerIndex)
        if player.craft.index ~= entity.index then return nil, 9 end
    end

    if not buff then
        local key = BuffsMod.getFreeKey()
        if not key then return nil, 2 end -- can't add more than 1000 buffs
        entity:addKeyedAbsoluteBias(stat, key, value)
        buff = {
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
          type = 4,
          player = _playerIndex
        }
        data.buffs[fullname] = buff
        entity:sendCallback("onBuffApplied", entity.index, 4, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        entity:sendCallback("onBuffApplied", entity.index, 4, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.refreshData()
    return true
end

-- API --
-- The following functions CAN be used directly ('BuffsMod.removeBuff') and via BuffsHelper.lua (BuffsHelper.removeBuff)
function BuffsMod.removeBuff(name)
    return BuffsMod.removeBuffWithType("B_"..name)
end

function BuffsMod.removeBaseMultiplier(name)
    return BuffsMod.removeBuffWithType("BM_"..name)
end

function BuffsMod.removeMultiplier(name)
    return BuffsMod.removeBuffWithType("M_"..name)
end

function BuffsMod.removeMultiplyableBias(name)
    return BuffsMod.removeBuffWithType("MB_"..name)
end

function BuffsMod.removeAbsoluteBias(name)
    return BuffsMod.removeBuffWithType("AB_"..name)
end

function BuffsMod.removeBuffWithType(fullname, buffType)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "removeBuffWithType",
          args = {fullname, buffType}
        }
        return nil, 0
    end
    if string.find(fullname, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if buffType then
        local prefix = buffPrefixes[buffType]
        if prefix then
            fullname = prefix..fullname
        end
    end
    local buff = data.buffs[fullname]
    if not buff then return false end -- can't find
    local entity = Entity()
    if buff.type == 5 then -- remove all bonuses
        local scripts
        for _, effect in ipairs(buff.effects) do
            if effect.script then -- custom entity script
                if effect.index then
                    if not scripts then scripts = entity:getScripts() end
                    local effectScript = "data/scripts/entity/buffs/"..effect.script..".lua"
                    local script = scripts[effect.index]
                    if script and string.find(script, effectScript, 1, true) then
                        entity:removeScript(effect.index)
                        Log:Debug("(%s) Removing buff script: %i", debugName, effect.index)
                    else
                        Log:Error("(%s) Couldn't remove buff script '%i', paths don't match: '%s' ~= '%s' - will be automatically fixed when possible", debugName, effect.index, effectScript, script or "")
                        data.fixEffects = true
                    end
                end
            elseif effect.customStat and effect.target ~= Helper.Target.Player then -- custom stat
                local entityStat = Helper.Stats[effect.customStat]
                if entityStat then
                    entityStat.onRemove(nil, entity, unpack(effect.args))
                end
            elseif effect.type then -- vanilla StatsBonuses
                entity:removeBonus(effect.key)
                data.freeKeys[#data.freeKeys+1] = effect.key
            end
        end
    else
        entity:removeBonus(buff.key)
        data.freeKeys[#data.freeKeys+1] = buff.key
    end
    entity:sendCallback("onBuffRemoved", entity.index, buff.type, table.deepcopy(buff))
    data.buffs[fullname] = nil
    BuffsMod.refreshData()
    return true
end

function BuffsMod.getBuffs()
    if not isReady then return {}, 0 end
    local r = {}
    for _, buff in pairs(data.buffs) do
        r[#r+1] = table.deepcopy(buff)
    end
    return r
end

function BuffsMod.getBuff(name, type)
    if not isReady then return nil, 0 end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        local buff = data.buffs[name]
        return buff and table.deepcopy(buff) or nil
    end
    for _, buff in pairs(data.buffs) do
        if buff.name == name then
            return table.deepcopy(buff)
        end
    end
end

function BuffsMod.isReady()
    return isReady
end

end