local item = ...
local game = item:get_game()

item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_metal_block_cane")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(5) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = map:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  x = x + game:dx(16)[direction]
  y = y + game:dy(16)[direction]
  local obstacle = hero:test_obstacles(game:dx(16)[direction], game:dy(16)[direction])

  if not map.created_metal_block or not map.created_metal_block:exists() then --no block exists
    if obstacle then sol.audio.play_sound"wrong" item:set_finished() return end
    if map.create_poof then map:create_poof(x, y+4, z) end
    map.created_metal_block = map:create_custom_entity{
      x=x, y=y, layer=z, direction=0, width=16, height=16, sprite="blocks/conductive_block", model="world_objects/conductive_block"
    }
    map.created_metal_block:set_origin(8, 13)
    map.created_metal_block.can_conduct_electricity = true

  else --block already exists
    map:create_poof(map.created_metal_block:get_position())
    map.created_metal_block:remove()
    map.created_metal_block = nil
  end

  item:set_finished()
end)

