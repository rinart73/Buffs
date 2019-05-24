if onClient() then return end

-- namespace RepairShipBuff
RepairOrDamageBuff = {}

function RepairOrDamageBuff.initialize(isShield, amount, frequency)
    print("RepairOrDamageBuff", isShield, amount, frequency)
    -- heal or damage shield/durability
end

function RepairOrDamageBuff.onAdded()
    
end

function RepairOrDamageBuff.onRemove() -- Called when the script is about to be removed from the object, before the removal
    
end