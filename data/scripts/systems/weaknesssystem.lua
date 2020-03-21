function onInstalled(seed, rarity, permanent) -- overridden
    if onClient() then return end

    local entity = Entity()
    if not entity then return end

    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, permanent)

    -- DON'T do that, it interferes with other scripts
    --[[-- the upgrades are unique, so we can just reset the weakness
    local durability = Durability()
    if not durability then return end
    durability:resetWeakness()
    durability.maxDurabilityFactor = 1]]

    if permanent then
        SpawnUtility.addWeakness(entity, weaknessType, dmgFactor, hpBonus)
    end
end

function onUninstalled(seed, rarity, permanent) -- overridden
    if onClient() then return end

    local entity = Entity()
    if not entity then return end

    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, permanent)

    -- DON'T do that, it interferes with other scripts
    --[[local durability = Durability()
    if not durability then return end

    durability:resetWeakness()
    durability.maxDurabilityFactor = 1]]

    if permanent then
        SpawnUtility.resetWeakness(entity, hpBonus)
    end
end