--
local config = {
  distance = 160, --range
  speed = 300,
  stun_length = 500, --amount of time for which enemies are stunned when hit by the hookshot (assumes an enemy:stagger(length) function)
  slack_delay = 120, --amount of time (in ms) after the hookstart starts retracting that the rope goes slack (this is just an asthetic choice)

  --Entity types which can be hooked, pulling the hero to them.
  --Additionally, any entity with the property "hookshot_target" or where entity.hookshot_target == true
  --or with a method entity:is_hookable() which returns true will also be hookable.
  hookable_entity_types = {
    "chest",
    "block",
  },

  --Entities of these types, with these sprites, will be hookable as well. This is useful if you want some destructables to be hookable, for example
  hookable_by_animation_set = {
    ["destructible"] =
      {
        "destructibles/bush", 
        "destructibles/pumpkin_small",
      },
    ["custom_entity"] =
      {
        "foliage/hookseed",
      },
  },

  --Entity types which can be snagged and retrieved with the hookshot. 
  --Additionally, any entity with entity.hookshot_catchable == true, or with the property "hookshot_catchable",
  --or with the method entity:is_catchable_with_hookshot() which returns true, will also be retrievable
  catchable_entity_types = {
    "pickable",
  },
}
--]]

--[[
local config = {
  distance = 160,
  speed = 300,
  stun_length = 500,
  slack_delay = 120,
  hookable_entity_types = {
    "chest",
    "block",
  },
  hookable_by_animation_set = {
    destructible =
      {
        "destructibles/bush", 
        "destructibles/pumpkin_small",
      },
    custom_entity =
      {
        "foliage/hookseed",
      },
  },
  catchable_entity_types = {
    "pickable",
  },
}
--]]

return config
