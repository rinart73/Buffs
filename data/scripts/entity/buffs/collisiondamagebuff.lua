-- Deals extra damage to other ship when colliding with them
if onClient() then return end

-- namespace CollisionDamageBuff
CollisionDamageBuff = {}

local damage

function CollisionDamageBuff.initialize(amount)
    print("CollisionDamageBuff", amount)
    if amount then
        damage = math.max(0, amount)
        if damage == 0 then terminate() end

        Entity():registerCallback("onCollision", "onCollision")
    end
end

function CollisionDamageBuff.onCollision(self, other)
    local entity = Entity(other)
    if not entity.isShip or entity.isStation then return end
    if not entity.aiOwned and not Sector().pvpDamage then return end

    entity:inflictDamage(damage, 0, vec3(), self.index, DamageType.Collision)
    print("dealing collision damage")
end

function CollisionDamageBuff.secure()
    return damage
end

function CollisionDamageBuff.restore(amount)
    if not damage then
        damage = amount
        Entity():registerCallback("onCollision", "onCollision")
    end
end