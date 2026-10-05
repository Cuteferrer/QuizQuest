local item = ...
local game = item:get_game()

local magic_cost = 100
local windup_time = 400
local damage = 10
local num_beams = 15
local radius_around_hero = 72
local beam_fuse = 250
local storm_duration = 3000

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_firestorm")
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
  hero:set_animation("casting")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,200,100}
  --[[ light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100} --]]

  sol.timer.start(map, windup_time, function()
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
    --local angle = math.random(0, math.pi * 2)
    local angle = math.pi * 2 / num_beams * i
    local distance = math.random(24, radius_around_hero)
    local x = hx + math.cos(angle) * distance
    local y = hy + math.sin(angle) * distance
    local z = hz
    sol.timer.start(map, math.random(1, storm_duration), function()
      item:create_sunbeam(x, y, z)
    end)
  end
end


function item:create_sunbeam(x, y, z)
  local map = item:get_map()
  local target = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = "items/flame_pillar",
  }
  target:get_sprite():set_animation"target"
  sol.timer.start(target, beam_fuse, function()
    target:remove()
    sol.audio.play_sound"fire_ball"
    local beam = map:create_custom_entity{
      x=x, y=y-8, layer=z,
      width = 32, height = 32, direction = 0,
      sprite = "items/flame_pillar",
      model = "damaging_entity",
    }
    beam.damage = damage
    beam:set_origin(16, 29)
    local sprite = beam:get_sprite()
    sol.timer.start(map, sprite:get_num_frames() * sprite:get_frame_delay(), function()
      local flame = map:create_fire({x=x, y=y, layer=z})
      flame.harmless_to_hero = true
    end)
  end)
end
