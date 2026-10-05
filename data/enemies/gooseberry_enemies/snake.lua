local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local normal_speed = 20
local rush_range = 200
local rush_speed = 130
local max_rush_distance = 300
local alignment_threshold = 24

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
end

function enemy:on_restarted()
  sol.timer.start(enemy, 500, function() enemy.rushing = false end)
  movement = sol.movement.create("random_path")
  movement:set_speed(normal_speed)
  movement:start(enemy)
  sol.timer.start(enemy, 0, function()
    enemy:check_hero()
    return 40
  end)
end

function enemy:on_movement_changed(movement)
  sprite:set_direction(movement:get_direction4())
end


function enemy:check_hero()
  local aligned = enemy:is_aligned()
  if aligned and not enemy.rushing then
    enemy:rush_hero()
  end
end


function enemy:is_aligned()
  local x, y, z = enemy:get_position()
  local hx, hy, hz = hero:get_position()
  local aligned = enemy:is_in_same_region(hero)
  and enemy:get_distance(hero) <= rush_range
  and z == hz
  and (math.abs(x - hx) <= alignment_threshold or math.abs(y - hy) <= alignment_threshold )
  return aligned
end


function enemy:rush_hero()
  enemy.rushing = true
  enemy:stop_movement()
  local m = sol.movement.create"straight"
  m:set_angle(enemy:get_direction4_to(hero) * math.pi / 2)
  m:set_speed(rush_speed)
  m:set_max_distance(max_rush_distance)
  m:start(enemy, function()
    enemy:restart()
  end)
  function m:on_obstacle_reached()
    enemy:restart()
  end
end
