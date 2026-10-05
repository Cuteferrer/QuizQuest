local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

local attack_range = 56
local idle_speed = 15
local attack_speed = 75

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  local shadow_sprite = enemy:create_sprite("shadows/shadow_4")
  shadow_sprite:set_xy(0, 8)
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior"flying"
  enemy:set_dying_sprite_id("enemies/enemy_killed_projectile")
end

function enemy:on_restarted()
  movement = sol.movement.create("random")
  movement:set_speed(15)
  movement:start(enemy)
  sol.timer.start(300, function()
    return enemy:check_hero()
  end)
end

function enemy:on_movement_changed(movement)
  sprite:set_direction(movement:get_direction4())
end


function enemy:check_hero()
  if not enemy:exists() then return end
  local x, y, z = enemy:get_position()
  if enemy:get_distance(hero) <= attack_range and hero:get_layer() == z then
    enemy:stop_movement()
    local m = sol.movement.create"target"
    m:set_target(hero)
    m:set_speed(attack_speed)
    m:start(enemy)
    sol.timer.start(enemy, 2000, function()
      m:stop()
      enemy:restart()
    end)
  else --hero not spotted, return true to repeat timer
    return true
  end
end


function enemy:on_attacking_hero()
  if hero.build_up_status_effect then
    hero:build_up_status_effect("poison", 40)
  end
  hero:start_hurt(enemy:get_damage())
end
