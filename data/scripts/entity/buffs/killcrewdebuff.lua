if onClient() then return end

-- namespace KillCrewBuff
KillCrewBuff = {}

function KillCrewBuff.initialize(frequency, isEqual, whiteList, blackList)
    print("KillCrewBuff", frequency, isEqual, whiteList, blackList)
end

function KillCrewBuff.onAdded()
    
end

function KillCrewBuff.onRemove() -- Called when the script is about to be removed from the object, before the removal
    
end