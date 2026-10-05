local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local walking_speed = 20

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
end

function enemy:on_restarted()
  enemy:stop_movement()
  sprite:set_animation"stopped"
  sol.timer.start(enemy, math.random(500, 1500), function() enemy:start_movement() end)
end


function enemy:start_movement()
  sprite:set_animation"walking"
  local angle = ( math.random( 3 * math.pi / 4 * 100, 5 * math.pi / 4 * 100 ) / 100 ) + math.pi * math.random(0, 1)
  local m = sol.movement.create"straight"
  m:set_speed(25)
  m:set_angle(angle)
  m:set_smooth(false)
  m:set_max_distance(enemy:get_size() * math.random(2, 5) )
  m:start(enemy, function() enemy:restart() end)
  function m:on_obstacle_reached() enemy:restart() end
end


function enemy:on_movement_changed(movement)
  local angle = movement:get_angle()
  if angle > math.pi / 2 and angle < (3 * math.pi / 2) then
    sprite:set_direction(2)
  else
    sprite:set_direction(0)
  end
end