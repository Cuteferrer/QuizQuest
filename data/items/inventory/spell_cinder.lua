local item = ...
local game = item:get_game()

local magic_cost = 33
local fuse_duration = 150
local initial_speed = 150
local num_flames = 6
local spread_angle = math.pi / 2
local flame_distance = 72

function item:on_started()
  local savegame_variable = "possession_spell_cinder"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
  item:set_ammo("_magic")
end
 

function item:on_using()
  local hero = game:get_hero()
  if item:try_spend_ammo(magic_cost) then
    local map = game:get_map()
    hero:freeze()
    hero:set_animation("charging")
    sol.timer.start(hero, 50, function()
      hero:set_animation("throwing", function()
        hero:set_animation"stopped"
        hero:unfreeze()
        item:set_finished()
      end)
    end)
    sol.timer.start(map, 300, function()
      sol.audio.play_sound("fire_ball")
      local x, y, z = hero:get_position()
      local direction = game:get_direction_held()
      local projectile = map:create_custom_entity{
        x=x, y=y, layer=z,
        width=16, height=16, direction = 0,
        sprite = "hero_projectiles/fireball",
        model = "hero_projectiles/general",
      }
      projectile:set_type"fireball"
      local angle = direction * math.pi / 4
      projectile:shoot(angle)
      projectile.speed = initial_speed
      projectile:shoot(angle)
      sol.timer.start(projectile, fuse_duration, function()
        local x, y, z = projectile:get_position()
        projectile:remove()
        --explode into flames:
        sol.audio.play_sound("fire_ball2")
        for i = 0, num_flames - 1 do
          --[[local flame = map:create_fire{x=x, y=y, layer=z}
          local m = sol.movement.create"straight"
          m:set_angle(angle - (spread_angle / 2) + (spread_angle / (num_flames - 1) * i))
          m:set_speed(initial_speed)
          m:set_max_distance(flame_distance)
          m:start(flame) --]]
          local flame = map:create_custom_entity{
            x=x, y=y, layer=z,
            width=16, height=16, direction = 0,
            sprite = "hero_projectiles/fireball",
            model = "hero_projectiles/general",
          }
          flame:set_type"fireball"
          flame.speed = initial_speed
          flame.range = flame_distance
          flame:shoot(angle - (spread_angle / 2) + (spread_angle / (num_flames - 1) * i))
        end
      end)

    end)
  else
    sol.audio.play_sound"wrong"
    hero:unfreeze()
    item:set_finished()
  end
end
