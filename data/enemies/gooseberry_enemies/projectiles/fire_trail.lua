local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_invincible()
  enemy:set_obstacle_behavior"flying"
  enemy.fire_immunity = true
end

function enemy:on_restarted()
  sol.timer.start(enemy, 100, function()
    local x,y,z = enemy:get_position()
    map:create_fire{x=x, y=y, layer=z,properties={{key = "burn_duration", value = "10"}}}
    return true
  end)
end
