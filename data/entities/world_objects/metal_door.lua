--A big metal sliding door
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity.is_magnetic = true
  entity.bound_in_by_track = true
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  entity:set_can_traverse("hero", function(entity, hero)
    return false
  end)
  entity:set_can_traverse("custom_entity", function(entity, other)
    print"Custom entity traverse test"
  end)
end
