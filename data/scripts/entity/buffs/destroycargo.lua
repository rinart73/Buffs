-- Destroys cargo over time
if onClient() then return end

-- namespace DestroyCargoBuff
DestroyCargoBuff = {}

local data

function DestroyCargoBuff.initialize(volume, frequency)
    if volume and frequency then
        data = {
          volume = volume,
          frequency = frequency
        }
    end
end

function DestroyCargoBuff.secure()
    return data
end

function DestroyCargoBuff.restore(_data)
    if _data then
        data = _data
    end
end

function DestroyCargoBuff.getUpdateInterval()
    return data and data.frequency or 1
end

function DestroyCargoBuff.update()
    if not data then return end -- we CAN'T terminate buffs even if arguments are wrong - this will mess up other scripts!

    Entity():destroyCargo(data.volume)
end