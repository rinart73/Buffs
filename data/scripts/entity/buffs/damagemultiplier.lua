-- Increases all incoming damage
if onClient() then return end

-- namespace DamageMultiplierBuff
DamageMultiplierBuff = {}

local multiplier

function DamageMultiplierBuff.initialize(amount)
    if amount then
        multiplier = amount
        local entity = Entity()
        entity.damageMultiplier = entity.damageMultiplier + amount
    end
end

function DamageMultiplierBuff.onRemove() -- Called when the script is about to be removed from the object, before the removal
    if not multiplier then
        eprint("[ERROR][Buffs]: Couldn't remove multiplier because it's nil")
        return
    end
    local entity = Entity()
    entity.damageMultiplier = entity.damageMultiplier - multiplier
end

function CollisionDamageBuff.secure()
    return multiplier
end

function CollisionDamageBuff.restore(amount)
    if amount then
        multiplier = amount
    end
end