local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity.is_magnetic = true
  entity:set_modified_ground"traversable"
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("lava", true)

  --Set unstable floor property so ground isn't saved:
  entity:set_property("unstable_floor", "true")
end
