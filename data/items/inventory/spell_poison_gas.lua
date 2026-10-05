local item = ...
local game = item:get_game()

local magic_cost = 15
local damage = 10
local num_clouds = 5
local cloud_radius = 32
local spread = math.rad(120)

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_poison_gas")
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
  local direction = hero:get_direction()

  hero:set_animation("spear_attack_heavy", function()
    hero:set_animation"stopped"
    item:set_finished()
  end)

  for i = 1, num_clouds do
    --local dx = math.cos((math.pi * 2 / num_clouds * i - 1)) * cloud_radius
    --local dy = math.sin((math.pi * 2 / num_clouds * i - 1)) * cloud_radius
    local cloud = map:create_custom_entity{
      x=x + game:dx(8)[direction],
      y=y + game:dy(8)[direction],
      layer=z,
      width = 32, height = 32, direction = 0,
      model = "poison_gas",
      sprite = "entities/enemy_projectiles/gas",
    }
    cloud:set_origin(16, 29)
    cloud.ignore_hero = true
    cloud.enemy_poison_amount = 10

    local angle = (spread/2 * -1) + (spread/num_clouds * i) + (direction * math.pi / 2) - math.rad(10)
    local m = sol.movement.create"straight"
    m:set_angle(angle)
    m:set_max_distance(cloud_radius)
    m:set_speed(70)
    m:set_ignore_obstacles(true)
    m:start(cloud)
  end
end)

