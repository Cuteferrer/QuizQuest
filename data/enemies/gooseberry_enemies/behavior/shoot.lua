local manager = {}

function manager:apply(enemy)
  local map = enemy:get_map()
  local hero = map:get_hero()
  local width, height = enemy:get_size()
  local spawn_offset = math.max(width, height)
  local dx = function(offset)
    return {[0] = offset, [1] = 0, [2] = offset * -1, [3] = 0}
  end
  local dy = function(offset)
    return {[0] = 0, [1] = offset * -1, [2] = 0, [3] = offset}
  end

  function enemy:aligned_to_shoot(DISTANCE_THRESHOLD, ANGLE_THRESHOLD)
    local sprite = enemy:get_sprite()
    DISTANCE_THRESHOLD = DISTANCE_THRESHOLD or 140
    ANGLE_THRESHOLD = ANGLE_THRESHOLD or math.rad(30)
    local aligned = false
    local direction = sprite:get_direction()
    local angle = direction * math.pi/2
    angle = angle + 2*math.pi --normalize angle for comparison
    local angle_to_hero = enemy:get_angle(hero) + 2*math.pi
    if angle - angle_to_hero <= ANGLE_THRESHOLD
    and enemy:get_distance(hero) <= DISTANCE_THRESHOLD then
      aligned = true
    end
    return aligned
  end

  function enemy:shoot_orthogonal(props)
    props = props or {}
    local sprite = enemy:get_sprite()
    local direction = sprite:get_direction()
    local speed = props.speed or 200
    local shoot_delay = props.shoot_delay or 300
    local max_distance = props.max_distance or 0
    local smooth = props.smooth or false
    local breed = props.breed or "gooseberry_enemies/projectiles/rock"
    sprite:set_animation("shooting", "walking")
    sol.timer.start(enemy, shoot_delay, function()
      if props.sound then sol.audio.play_sound(props.sound) end
      local projectile = enemy:create_enemy{
        breed = breed, direction = 0, x = dx(16)[direction], y = dy(16)[direction]
      }
      local m = sol.movement.create"straight"
      m:set_speed(speed)
      m:set_smooth(smooth)
      m:set_angle(sprite:get_direction() * math.pi / 2)
      m:set_max_distance(max_distance)
      m:start(projectile, function() projectile:remove() end)
      function m:on_obstacle_reached()
        projectile:remove()
      end
    end)
  end


  function enemy:shoot_omnidirectional(props)
    props = props or {}
    local sprite = enemy:get_sprite()
    local speed = props.speed or 140
    local shoot_delay = props.shoot_delay or 300
    local max_distance = props.max_distance or 0
    local smooth = props.smooth or false
    local breed = props.breed or "gooseberry_enemies/projectiles/rock"
    sprite:set_animation("shooting", "walking")
    sol.timer.start(enemy, shoot_delay, function()
      if props.sound then sol.audio.play_sound(props.sound) end
      local projectile = enemy:create_enemy{
        breed = breed, direction = 0, x = dx(16)[direction], y = dy(16)[direction]
      }
      local m = sol.movement.create"straight"
      m:set_speed(speed)
      m:set_smooth(smooth)
      m:set_angle(enemy:get_angle(hero))
      m:set_max_distance(max_distance)
      m:start(projectile, function() projectile:remove() end)
      function m:on_obstacle_reached()
        projectile:remove()
      end
    end)
  end

end

return manager
