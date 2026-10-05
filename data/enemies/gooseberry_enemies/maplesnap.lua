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
  enemy.flammible = true
end

function enemy:on_restarted()
  sol.timer.start(enemy, 0, function()
    if enemy.flying then
      enemy:land()
      return math.random(1000, 1500)
    else
      enemy:takeoff()
      return math.random(1000, 1500)
    end
  end)

end

function enemy:takeoff()
  enemy:set_attack_consequence("sword", "protected")
  enemy:set_attack_consequence("arrow", "protected")
  sprite:set_animation("takeoff", function()
    sprite:set_animation"flying"
    enemy.flying = true
    local m = sol.movement.create"random"
    m:set_speed(80)
    m:start(enemy)
  end)
end


function enemy:land()
  enemy:stop_movement()
  sprite:set_animation("landing", function()
    sprite:set_animation"stopped"
    enemy.flying = false
    enemy:set_default_attack_consequences()
  end)
end

function enemy:on_immobilized()
  enemy:set_default_attack_consequences()
end
