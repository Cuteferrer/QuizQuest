local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

enemy.respawn_do_not_index = true

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_dying_sprite_id("enemies/enemy_killed_projectile")
  enemy:set_has_shadow(true, "18")
end
