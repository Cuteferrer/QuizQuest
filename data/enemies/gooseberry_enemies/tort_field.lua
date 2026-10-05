local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local PROJECTILE_SPEED = 180
local SHOOT_DIST = 200
local SHOOT_ANGLE = math.rad(45)

require("enemies/gooseberry_enemies/behavior/shoot"):apply(enemy)

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(15)
  enemy:set_size(32, 32)
  enemy:set_damage(2)
end

function enemy:on_restarted()
  enemy:start_movement()
  sol.timer.start(enemy, math.random(2000,4000), function()
    enemy:stop_movement()
    sprite:set_animation"stopped"
    if enemy:aligned_to_shoot(SHOOT_DIST, SHOOT_ANGLE) then
      sprite:set_direction(enemy:get_direction4_to(hero))
      enemy:shoot_orthogonal({
        sound = "lamp",
        breed = "gooseberry_enemies/projectiles/big_rock",
        speed = 250,
      })
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
