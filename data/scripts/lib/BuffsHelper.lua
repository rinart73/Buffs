local BuffsHelper = {}

-- ENUMS --
-- value = (base_value * BaseMultiplier + MultiplyableBias) * Multiplier + AbsoluteBias
BuffsHelper.Type = {
  BaseMultiplier = 1,
  Multiplier = 2,
  MultiplyableBias = 3,
  AbsoluteBias = 4,
  Buff = 5 -- complex buff with multiple bonuses
}

BuffsHelper.ApplyMode = {
  Add = 1, -- add if doesn't exist
  AddOrRefresh = 2, -- refresh duration or add if doesn't exist
  AddOrCombine = 3, -- combine duration or add if doesn't exist
  Refresh = 4, -- refresh duration, DON'T add if doesn't exist
  Combine = 5 -- combine duration, DON'T add if doesn't exist
}

-- API --
-- For explanation look at 'buffs.lua', line 540+
function BuffsHelper.addBuff(entity, ...)
  entity:invokeFunction("data/scripts/entity/buffs.lua", "_addBuff", ...)
end

function BuffsHelper.addBaseMultiplier(entity, ...)
  entity:invokeFunction("data/scripts/entity/buffs.lua", "_addBaseMultiplier", ...)
end

function BuffsHelper.addMultiplier(entity, ...)
  entity:invokeFunction("data/scripts/entity/buffs.lua", "_addMultiplier", ...)
end

function BuffsHelper.addMultiplyableBias(entity, ...)
  entity:invokeFunction("data/scripts/entity/buffs.lua", "_addMultiplyableBias", ...)
end

function BuffsHelper.addAbsoluteBias(entity, ...)
  entity:invokeFunction("data/scripts/entity/buffs.lua", "_addAbsoluteBias", ...)
end

-- CUSTOM EFFECTS --
BuffsHelper.Custom = {}

--[[ Adds custom effect for client and server.
* shortName - bonus name to be used as 'BuffsHelper.Custom.ShortName'
* scriptName - bonus script name without path and '.lua'. File should be in the "data/scripts/entity/buffs/" folder
* tooltipName - bonus name that will be translated and displayed in a tooltip.
* tooltipValueFunc - function that returns tooltip string with bonus value
]]
local function addCustomBonus(shortName, scriptName, tooltipName, tooltipValueFunc)
    BuffsHelper.Custom[shortName] = {
      script = scriptName,
      statName = tooltipName,
      statFunc = tooltipValueFunc,
      New = function(self, ...)
          return { script = self.script, args = {...} }
      end
    }
end

-- Built-in custom effects:

--[[ Inflicts extra damage to other ship on collision.
* amount - Extra damage, should be > 0. ]]
addCustomBonus("CollisionDamage", "collisiondamage", "Collision Damage"%_t, function(amount)
    return "+"..amount
end)

--[[ Increases/decreases all incoming damage.
* amount - Extra damage factor (0.2 = +20%)
]]
addCustomBonus("DamageMultiplier", "damagemultiplier", "Damage"%_t, function(amount)
    amount = amount * 100
    amount = amount > 0 and "+"..amount or amount
    return amount.."%"
end)

--[[ Destroys random cargo 'volume' every 'frequency' seconds. ]]
addCustomBonus("DestroyCargo", "destroycargo", "Cargo Destruction"%_t, function(volume, frequency)
    volume = tonumber(string.format("%.2f", volume / frequency)) -- 3 will be displayed as 3 and not 3.00
    frequency = ("${amount}/s"%_t) % { amount = volume }
    return volume > 0 and "+"..frequency or frequency
end)

--[[ Kills 'amount' random crew members every 'frequency' seconds. ]]
addCustomBonus("KillCrew", "killcrew", "Crew Dies"%_t, function(amount, frequency)
    amount = tonumber(string.format("%.2f", amount / frequency))
    frequency = ("${amount}/s"%_t) % { amount = amount }
    return amount > 0 and "+"..frequency or frequency
end)

--[[ Changes durability by 'amount' every 'frequency' seconds. ]]
addCustomBonus("ChangeDurability", "changedurability", "Durability"%_t, function(amount, frequency)
    amount = tonumber(string.format("%.2f", amount / frequency))
    frequency = ("${amount}/s"%_t) % { amount = amount }
    return amount > 0 and "+"..frequency or frequency
end)

--[[ Changes shield durability by 'amount' every 'frequency' seconds. ]]
addCustomBonus("ChangeShield", "changeshield", "Shield"%_t, function(amount, frequency)
    amount = tonumber(string.format("%.2f", amount / frequency))
    frequency = ("${amount}/s"%_t) % { amount = amount }
    return amount > 0 and "+"..frequency or frequency
end)

--[[
BuffsHelper.addBuff("Spiky", { BuffsHelper.Custom.CollisionDamage:New(20) }, 60, BuffsHelper.ApplyMode.AddOrRefresh, false, "Spiky")
BuffsHelper.addBuff("Bugs", { BuffsHelper.Custom.DestroyCargo:New(10, 5) }, 60, BuffsHelper.ApplyMode.AddOrRefresh, false, "Bugs")
]]

return BuffsHelper