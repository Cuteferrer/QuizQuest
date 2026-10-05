local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local PROJECTILE_SPEED = 180
local SHOOT_DIST = 140
local SHOOT_ANGLE = math.rad(30)

require("enemies/gooseberry_enemies/behavior/shoot"):apply(enemy)

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
end

function enemy:on_restarted()
  enemy:start_movement()
  sol.timer.start(enemy, math.random(2000,4000), function()
    enemy:stop_movement(SHOOT_DIST, SHOOT_ANGLE)
    if enemy:aligned_to_shoot() then
      enemy:shoot_orthogonal({sound = "lamp"})
    end
    sol.timer.start(enemy, math.random(1000,3000), function()
      enemy:restart()
    end)
  end)
end

function enemy:start_movement()
  movement = sol.movement.create("random_path")
  movement:set_speed(24)
  function movement:on_changed()
    sprite:set_direction(movement:get_direction4())
  end
  movement:start(enemy)
end
