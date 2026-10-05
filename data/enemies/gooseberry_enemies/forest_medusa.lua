local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local walking_speed = 15

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(5)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior"flying"
end

function enemy:on_restarted()
  enemy:stop_movement()
  sol.timer.start(enemy, math.random(500, 1500), function() enemy:start_movement() end)
  local rand = math.random(1, 5)
  if rand < 3 and (enemy:get_distance(hero) < 90) then
    enemy:attack()
  end
end


function enemy:start_movement()
  sprite:set_animation"walking"
  local angle = math.pi * 2 / 100 * math.random(1, 100)
  local m = sol.movement.create"straight"
  m:set_speed(25)
  m:set_angle(angle)
  m:set_smooth(false)
  m:set_max_distance(enemy:get_size() * math.random(2, 5) )
  m:start(enemy, function() enemy:restart() end)
  function m:on_obstacle_reached() enemy:restart() end
end

function enemy:attack()
  sol.timer.stop_all(enemy)
  enemy:get_sprite():set_animation"attacking"
  sol.timer.start(enemy, 700, function()
    local num_projectiles = 8
    for i = 1, num_projectiles do
      local projectile = enemy:create_enemy{
        direction = 0, y = -4,
        breed = "gooseberry_enemies/projectiles/spore"
      }
      projectile:set_obstacle_behavior"flying"
      local m = sol.movement.create"straight"
      m:set_speed(85)
      m:set_max_distance(32)
      m:set_angle(math.pi * 2 / num_projectiles * i)
      m:start(projectile, function() projectile:remove() end)
      function m:on_obstacle_reached()
        projectile:remove()
      end
    end
    enemy:restart()
  end)
end
