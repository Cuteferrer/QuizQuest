local item = ...
local game = item:get_game()

local magic_cost = 30
local windup_time = 500
local damage = 15
local speed = 290
local attack_frequency = 50
local max_distance = 168

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_backdraft")
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
  hero:set_animation("punch_windup")
  local x, y, z = hero:get_position()
  --[[ portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,255,100} --]]
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,80} --]]

  sol.timer.start(map, windup_time, function()
    --portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation("punch", function()
      hero:set_animation"stopped"
      item:set_finished()
    end)
  end)

  sol.timer.start(hero, windup_time - 350, function() --delay to match animation
    item:create_attacks()
  end)
end)


function item:create_attacks()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, z = hero:get_position()
  local direction = hero:get_direction()
  local offset = 24

  local x = hx + game:dx(offset)[direction]
  local y = hy + game:dy(offset)[direction]
  item:create_sunbeam(x, y, z)
end


function item:create_sunbeam(x, y, z)
  local map = item:get_map()
  local hero = map:get_hero()
  local num_flames = 4
  local flame_spread = math.rad(90)
  local offset = 24

  local beam = map:create_custom_entity{
    x=x, y=y, layer=z,
    width = 32, height = 32, direction = 0,
    sprite = "items/flame_pillar",
    model = "damaging_entity",
  }
  beam.start_without_collision = true
  beam.damage = damage
  beam:set_origin(16, 29)
  local sprite = beam:get_sprite()

  --Create flame when pillar burns out
  sol.timer.start(map, sprite:get_num_frames() * sprite:get_frame_delay(), function()
    local flame = map:create_fire({x=x, y=y, layer=z})
    flame.harmless_to_hero = true
  end)

  --Create backdraft flames when pillar explodes
  sol.timer.start(map, 5 * sprite:get_frame_delay(), function()
    sol.audio.play_sound"fire_ball2"
    beam:activate_collision()

    local direction = hero:get_direction()
    local m = sol.movement.create"straight"
    m:set_angle(direction * math.pi / 2)
    m:set_speed(90)
    m:set_max_distance(8)
    m:start(hero)

    for i = 1, num_flames do
      local fx = x -- + game:dx(offset)[direction]
      local fy = y -- + game:dy(offset)[direction] 
      local flame = map:create_fire({x=fx, y=fy, layer=z})
      flame.harmless_to_hero = true
      local m = sol.movement.create"straight"
      local angle = (direction * math.pi / 2 + math.pi) - flame_spread / 2 + flame_spread / num_flames * i
      m:set_angle(angle)
      m:set_speed(180)
      m:set_max_distance(48)
      m:start(flame)
    end
  end)
end

