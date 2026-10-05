local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()

  entity:set_traversable_by(false)
  entity:set_traversable_by("hero", function(entity, other) return other:overlaps(entity) end)
  entity:set_drawn_in_y_order(true)

  entity:add_collision_test("touching", function(entity, other)
    if other.is_track_vehicle then
      other:hit_stopper()
    end
  end)
end
