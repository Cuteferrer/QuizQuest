local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local walking_speed = 25

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
  enemy:set_push_hero_on_sword(true)
end

function enemy:on_restarted()
  movement = sol.movement.create("random_path")
  movement:set_speed(walking_speed)
  movement:start(enemy)
  sprite:set_direction(movement:get_direction4())
  function movement:on_changed()
    sprite:set_direction(movement:get_direction4())
  end
end
