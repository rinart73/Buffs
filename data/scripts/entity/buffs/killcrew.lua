-- Kills crew over time
if onClient() then return end

-- namespace KillCrewBuff
KillCrewBuff = {}

local data
local rand = random()

function KillCrewBuff.initialize(amount, frequency)
    if amount and frequency then
        data = {
          amount = amount,
          frequency = frequency
        }
    end
end

function KillCrewBuff.secure()
    return data
end

function KillCrewBuff.restore(_data)
    if _data then
        data = _data
    end
end

function KillCrewBuff.getUpdateInterval()
    return data and data.frequency or 1
end

function KillCrewBuff.updateParallelSelf()
    if not data then return end -- we CAN'T terminate buffs even if arguments are wrong - this will mess up other scripts!
    local entity = Entity()
    if not entity.crew then return end

    entity.crew:kill(data.amount)
end