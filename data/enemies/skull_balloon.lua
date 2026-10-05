local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(8)
  enemy:set_damage(1)
  local shadow = enemy:create_sprite("shadows/shadow_medium")
  enemy:bring_sprite_to_back(shadow)
end

function enemy:on_restarted()
  enemy:set_can_attack(false)
  movement = sol.movement.create("random")
  movement:set_speed(15)
  movement:start(enemy)
end

function enemy:react_to_fire()
  enemy:hurt(3)
end