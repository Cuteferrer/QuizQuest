local item = ...
local game = item:get_game()

local magic_cost = 50
local damage = 10
local num_beams = 10
local radius_around_hero = 48
local beam_fuse = 500

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_sunbeam")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  hero:set_animation("kneeling")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,255,100}
  --[[ light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100} --]]

  sol.timer.start(map, 1000, function()
    portal_entity:remove()
    hero:set_animation"stopped"
    item:create_sunbeams()
    item:set_finished()
  end)
end)


function item:create_sunbeams()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, hz = hero:get_position()

  for i = 1, num_beams do
    local x = hx + math.cos(math.pi * 2 / num_beams * i) * radius_around_hero
    local y = hy + math.sin(math.pi * 2 / num_beams * i) * radius_around_hero
    local z = hz
    sol.timer.start(map, math.random(1, 400), function()
      item:create_sunbeam(x, y, z)
    end)
  end
end


function item:create_sunbeam(x, y, z)
  local map = item:get_map()
  local target = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = "items/sunbeam",
  }
  target:get_sprite():set_animation"target"
  sol.timer.start(target, beam_fuse, function()
    local beam = map:create_custom_entity{
      x=x, y=y-8, layer=z,
      width = 32, height = 32, direction = 0,
      sprite = "items/sunbeam",
      model = "damaging_entity",
    }
    beam.damage = damage
    beam:set_origin(16, 29)
    local sprite = beam:get_sprite()
    sol.timer.start(target, sprite:get_num_frames() * sprite:get_frame_delay(), function() target:remove() end)
  end)
end
