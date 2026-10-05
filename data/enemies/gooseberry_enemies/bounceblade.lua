local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(4)
  enemy:set_damage(1)
end

function enemy:on_restarted()
  require("enemies/gooseberry_enemies/behavior/movement_circle_bounce"):apply(enemy)
  enemy:switch_movement()
end


