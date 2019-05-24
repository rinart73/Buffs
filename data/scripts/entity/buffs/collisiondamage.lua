-- Deals extra damage to other ship on collision
if onClient() then return end

-- namespace CollisionDamageBuff
CollisionDamageBuff = {}

local damage

function CollisionDamageBuff.initialize(amount)
    if amount then
        damage = math.max(0, amount)
        Entity():registerCallback("onCollision", "onCollision")
    end
end

function CollisionDamageBuff.onCollision(self, other)
    if not damage or damage == 0 then return end -- we CAN'T terminate buffs even if arguments are wrong - this will mess up other scripts!
    local entity = Entity(other)
    if not entity.isShip and not entity.isStation then return end -- only damage ships and stations
    if not entity.aiOwned and not Sector().pvpDamage then return end -- no extra damage to player ships in pve sectors

    entity:inflictDamage(damage, 0, vec3(), entity.index, DamageType.Collision)
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