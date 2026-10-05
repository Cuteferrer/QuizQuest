--Used to create walls to bound in custom entities. If entity.bound_in_by_track == true then this will be a wall to it
--Can be used for carts on tracks, sliding doors, etc

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by("custom_entity", function(entity, other)
    if other.bound_in_by_track then
      return false
    else
      return true
    end
  end)
end
