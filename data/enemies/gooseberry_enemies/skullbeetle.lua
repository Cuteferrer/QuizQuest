local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
end

function enemy:on_restarted()
  movement = sol.movement.create("random_path")
  movement:set_speed(15)
  movement:start(enemy)
end

function enemy:on_movement_changed(movement)
  sprite:set_direction(movement:get_direction4())
end