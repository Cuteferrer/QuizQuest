local item = ...

local step_forward = function()
  local hero = sol.main.get_game():get_hero()
  local m = sol.movement.create("straight")
  local direction = hero:get_direction()
  m:set_angle(direction * math.pi / 2)
  m:set_max_distance(8)
  m:start(hero)
end

local function fire_attack(dist)
  local game = sol.main.get_game()
  local hero = game:get_hero()
  local map = hero:get_map()
  local x,y,z = hero:get_position()
  local direction = hero:get_direction()
  sol.timer.start(map, 200, function()
    map:create_fire{
      x=x + game:dx(dist)[direction],
      y=y + game:dy(dist)[direction],
      layer=z
    }
  end)
end


local function fire_attack(num_fires)
  local num_fires = num_fires or 3
  local game = sol.main.get_game()
  local hero = game:get_hero()
  local map = hero:get_map()
  local x,y,z = hero:get_position()
  local direction = hero:get_direction()
  sol.timer.start(map, 100, function()
    for i=1, num_fires or 3 do
      local flame = map:create_fire{
        x=x + game:dx(24)[direction],
        y=y + game:dy(24)[direction],
        layer=z
      }
      local m = sol.movement.create"straight"
      m:set_angle(hero:get_angle(flame) - math.rad(30) + math.rad(60)/num_fires * i)
      m:set_max_distance(24)
      m:set_speed(120)
      m:set_ignore_obstacles()
      m:start(flame, function() flame:remove() end)
    end
  end)
end




sol.modules.get_object("solforge"):temper_weapon(item,
  {
    item_id = item:get_name():gsub("/", "_"),

    attacks = {
      {
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/fire_sword",
        weapon_attack_animation = "swing",
        weapon_sound = "sword1",
        callback = function()
          step_forward()
          --fire_attack()
        end,
      },
      {
        hero_attack_animation = "sword_swing_backhand",
        weapon_sprite = "solforge_weapons/fire_sword",
        weapon_attack_animation = "reverse_swing",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/fire_sword",
        weapon_attack_animation = "swing",
        weapon_sound = "sword1",
        --callback = function() fire_attack() end,
      },
    },

    weapon_parameters = {
      attack_power = 1,
      damage_type = "fire",
      weight = 10,
      durability = 100,
      degradation = 5,
    }

  }
)


function item:enemy_hit_callback(enemy)
  enemy:build_up_status_effect("burn", 50)
end
