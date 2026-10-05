local item = ...
local game = item:get_game()

local magic_cost = 25
local windup_time = 200
local damage = 4
local speed = 200
local attack_frequency = 35
local max_distance = 250
local seed_spread = 20 --how much from the line in which its cast can the seed spread
local max_plants = 100 --maximum number of plants that can be created at once with this spell

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_plant_growth")
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
  if not item.plants then
    item.plants = {}
  end

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
  light_effect_entity:get_sprite():set_color_modulation{255,150,80} --]]

  sol.timer.start(map, windup_time, function()
    --portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation("throwing", function()
      hero:set_animation"stopped"
      item:set_finished()
    end)
    sol.timer.start(hero, 140, function() --delay to match animation
      item:create_attacks()
    end)
  end)
end)


function item:create_attacks()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, hz = hero:get_position()
  local direction = hero:get_direction()

  local target_entity = map:create_custom_entity{
    x=hx, y=hy, layer=hz,
    width = 8, height = 8, direction = 0,
  }
  target_entity:set_can_traverse_ground("shallow_water", true)
  target_entity:set_can_traverse_ground("deep_water", true)
  target_entity:set_can_traverse_ground("hole", true)
  target_entity:set_can_traverse_ground("lava", true)

  local m = sol.movement.create"straight"
  m:set_angle(direction * math.pi / 2)
  m:set_speed(speed)
  m:set_smooth(true)
  m:set_max_distance(max_distance)
  m:start(target_entity)

  local attack_timer = sol.timer.start(target_entity, attack_frequency, function()
    local x, y, z = target_entity:get_position()
    item:create_attack(x, y, z , direction)
    return attack_frequency
  end)

  local end_movement = function()
    target_entity:remove()
  end
  m.on_finished = end_movement
  m.on_obstacle_reached = end_movement
  
end


function item:create_attack(x, y, z, direction)
  local map = item:get_map()
  local ground = map:get_ground(x, y, z)
  local sprites = {
    "generic",
    "barley",
    "nettle_short",
    "pumpkin_leaves",
    "sprig",
  }
  local rand_sprite = "foliage/" .. sprites[math.random(#sprites)]
  if direction % 2 == 0 then --horizontal
    y = y + math.random(seed_spread * -1, seed_spread)
    x = x + math.random(-8, 8)
  else
    x = x + math.random(seed_spread * -1, seed_spread)
    y = y + math.random(-8, 8)
  end
  if ground == "traversable" then
    local plant = map:create_custom_entity{
      x=x, y=y, layer=z, width=16, height=16, direction=0,
      model = "environment/foliage",
      sprite = rand_sprite,
    }
    item.plants[#item.plants + 1] = plant
    if #item.plants > max_plants then
      item.plants[1]:remove()
      table.remove(item.plants, 1)
    end
  end
end




