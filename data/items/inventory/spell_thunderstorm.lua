local item = ...
local game = item:get_game()

local magic_cost = 100
local windup_time = 400
local damage = 10
local num_beams = 7
local radius_around_hero = 72
local beam_fuse = 250
local bolt_delay_min, bolt_delay_max = 100, 600

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_thunderstorm")
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
  portal_entity:get_sprite():set_color_modulation{255,255,100}
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100} --]]

  sol.timer.start(map, windup_time, function()
    portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation"stopped"
    item:create_bolts()
    item:set_finished()
  end)
end)


function item:create_bolts()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, hz = hero:get_position()

  for i = 1, num_beams do
    --local angle = math.random(0, math.pi * 2)
    local angle = math.pi * 2 / num_beams * i
    local distance = math.random(radius_around_hero - 16, radius_around_hero + 8)
    local x = hx + math.cos(angle) * distance
    local y = hy + math.sin(angle) * distance
    local z = hz
    map:create_lightning_bolt{
      x=x, y=y, layer=z,
      delay = math.random(bolt_delay_min, bolt_delay_max),
      seek_enemy_distance = 48,
    }
  end
end