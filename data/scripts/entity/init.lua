if onServer() then
    local entity = Entity()
    if entity.isShip or entity.isStation then
        entity:addScriptOnce("data/scripts/entity/buffs.lua")
    end
end