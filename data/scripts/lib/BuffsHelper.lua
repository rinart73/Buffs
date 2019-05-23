local BuffsHelper = {}

BuffsHelper.Type = {
  BaseMultiplier = 1,
  Multiplier = 2,
  MultiplyableBias = 3,
  AbsoluteBias = 4,
  Buff = 5
}

BuffsHelper.ApplyMode = {
  Add = 1, -- add if doesn't exist
  AddOrRefresh = 2, -- refresh duration or add buff if doesn't exist
  AddOrCombine = 3, -- combine duration or add buff if doesn't exist
  Refresh = 4, -- refresh duration, DON'T add if doesn't exist
  Combine = 5 -- combine duration, DON'T add if doesn't exist
}

BuffsHelper.Effects = {}

BuffsHelper.Effects.Radiation = {
  icon = "Radiation",
  name = "Radiation",
  description = ""
  script = "data/scripts/entity/buffs/radiationdebuff.lua"
}

return BuffsHelper