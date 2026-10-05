local manager = {}

function manager:apply(enemy)

  function enemy:switch_movement(speed, radius)
    speed = speed or 2
    radius = radius or 48
    local x,y,z = enemy:get_position()

    local random_angle = math.rad(math.random(0,360))
    local new_center_x = x + radius * math.cos(random_angle)
    local new_center_y = y + radius * math.sin(random_angle)

    local m = sol.movement.create"circle"
    m:set_center(new_center_x, new_center_y)
    m:set_angle_from_center(enemy:get_angle(new_center_x, new_center_y) + math.pi)
    m:set_radius(radius)
    m:set_angular_speed(speed)
    if math.random(1,2) == 2 then
      m:set_clockwise()
    else
      m:set_clockwise(false)
    end

    m:start(enemy)

    if enemy.recircle_timer then enemy.recircle_timer:stop() end
    enemy.recircle_timer = sol.timer.start(enemy, 2000, function() enemy:switch_movement(speed, radius) end)

    function m:on_obstacle_reached()
      enemy.recircle_timer:stop()
      enemy:switch_movement(speed, radius)
    end
  end

end

return manager