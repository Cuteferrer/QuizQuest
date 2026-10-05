local door_meta = sol.main.get_metatable"door"

--Make doors Y Ordered, sized to sprite size, and have initial state
door_meta:register_event("on_created", function(door)
  local sprite = door:get_sprite()
  local sprite_id = sprite:get_animation_set() 
  door:set_drawn_in_y_order(true)
  if sprite:get_direction() == 3 then
    local width, height = door:get_size()
    local sw, sh = door:get_sprite():get_size()
    door:set_size(sw, height)
    door:set_origin(sw / 2 - 8, height - 16)
  end

  if door:get_property"initial_state" == "open" then
    door:set_open(true)
  end
end)


