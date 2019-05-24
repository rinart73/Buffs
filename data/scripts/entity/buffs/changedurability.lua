-- Heals or damages durability over time
if onClient() then return end

-- namespace ChangeDurabilityBuff
ChangeDurabilityBuff = {}

local data

function ChangeDurabilityBuff.initialize(amount, frequency)
    if amount and frequency then
        data = {
          amount = amount,
          frequency = frequency
        }
    end
end

function ChangeDurabilityBuff.secure()
    return data
end

function ChangeDurabilityBuff.restore(_data)
    if _data then
        data = _data
    end
end

function ChangeDurabilityBuff.getUpdateInterval()
    return data and data.frequency or 1
end

function ChangeDurabilityBuff.update()
    if not data then return end -- we CAN'T terminate buffs even if arguments are wrong - this will mess up other scripts!

    local entity = Entity()
    if data.amount > 0 then
        entity.durability = math.min(entity.maxDurability, entity.durability + data.amount)
    else
        entity.durability = math.max(0, entity.durability + data.amount)
    end
end