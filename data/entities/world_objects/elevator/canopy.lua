local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  local x, y, z = entity:get_position()
  entity:set_position(x, y+1, z)
end
