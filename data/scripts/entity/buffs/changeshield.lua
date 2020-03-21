-- Heals or damages shield durability over time
if onClient() then return end

-- namespace ChangeShieldBuff
ChangeShieldBuff = {}

local data

function ChangeShieldBuff.initialize(amount, frequency)
    if amount and frequency then
        data = {
          amount = amount,
          frequency = frequency
        }
    end
end

function ChangeShieldBuff.secure()
    return data
end

function ChangeShieldBuff.restore(_data)
    if _data then
        data = _data
    end
end

function ChangeShieldBuff.getUpdateInterval()
    return data and data.frequency or 1
end

function ChangeShieldBuff.updateParallelSelf()
    if not data then return end -- we CAN'T terminate buffs even if arguments are wrong - this will mess up other scripts!
    
    local entity = Entity()
    if entity.shieldMaxDurability then
        entity:changeShield(data.amount)
    end
end