local item = ...
local game = item:get_game()

item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_staff_of_teningur")
  item:set_assignable(true)
end)


function item:on_using()
  local map = item:get_map()
  local hero = map:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  x = x + game:dx(16)[direction]
  y = y + game:dy(16)[direction]
  local obstacle = hero:test_obstacles(game:dx(16)[direction], game:dy(16)[direction])

  if not map.teningur_block or not map.teningur_block:exists() then --no block exists
    if obstacle then sol.audio.play_sound"wrong" item:set_finished() return end
    if map.create_poof then map:create_poof(x, y+4, z) end
    map.teningur_block = map:create_block{
      x=x, y=y, layer=z, pushable = true, pullable = false, sprite="blocks/teningur_block",
    }
  else --block already exists
    map:create_poof(map.teningur_block:get_position())
    map.teningur_block:remove()
    map.teningur_block = nil
  end
  hero:set_animation("rod_swing", function()
    hero:set_animation"stopped"
    item:set_finished()
  end)
end

