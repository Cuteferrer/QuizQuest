local item = ...
local game = item:get_game()

local magic_cost = 40
local windup_time = 400
local damage = 3
local num_attacks = 9
local initial_radius = 16
local max_radius = 96
local duration = 1000

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_ice_wind")
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
  light_effect_entity:get_sprite():set_color_modulation{100,200,255} --]]

  sol.timer.start(map, windup_time, function()
    --portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation"stopped"
    item:create_attacks()
    item:set_finished()
  end)
end)


function item:create_attacks()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, hz = hero:get_position()

  for i = 1, num_attacks do
    --local angle = math.random(0, math.pi * 2)
    local angle = math.pi * 2 / num_attacks * i
    local distance = initial_radius --math.random(radius_around_hero - 16, radius_around_hero + 8)
    local x = hx + math.cos(angle) * distance
    local y = hy + math.sin(angle) * distance
    local z = hz
    local ice = map:create_ice_blast(x, y, z)
    ice.harmless_to_hero = true
    ice:remove_sprite(ice:get_sprite())
    ice:create_sprite("elements/ice_sparkle")
    local m = sol.movement.create"circle"
    m:set_center(hero)
    m:set_ignore_obstacles(true)
    m:set_angle_from_center(hero:get_angle(ice))
    m:set_radius(initial_radius)
    m:set_radius_speed(120)
    m:set_angular_speed(math.pi)
    m:start(ice)
    m:set_radius(max_radius)
    sol.timer.start(ice, duration, function()
      ice:remove()
    end)

    local collided_entities = {}
    ice:add_collision_test("sprite", function(ice, other)
      if other:get_type() == "enemy" and not collided_entities[other] then
        collided_entities[other] = true
        if other.process_hit then
          other:process_hit(damage)
        else
          other:hurt(damage)
        end
        if other.build_up_status_effect then other:build_up_status_effect("cold", 30) end
      end
    end)
  end
end