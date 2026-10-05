local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(8,8)
  enemy:set_origin(4, 5)
  enemy:set_life(1)
  enemy:set_damage(1)
end

function enemy:on_restarted()

end

function enemy:on_attacking_hero()
  if hero.build_up_status_effect then
    hero:build_up_status_effect("poison", 40)
  end
  hero:start_hurt(enemy:get_damage())
end
