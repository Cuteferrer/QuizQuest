local manager = {}

function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  function enemy:create_vengeful_spirit(props)
    local x, y, z = props.x, props.y, props.layer
    if (props.x == nil or props.y == nil) then
      x, y, z = enemy:get_position()
    end
    local projectile_speed = props.projectile_speed or 180
    local track_frequency = props.track_frequency or 10
    local track_step = props.track_step or 20
    local track_duration = props.track_duration or 3000
    local projectile_lifetime = props.projectile_lifetime or 2000
    local damage = props.damage or enemy.base_damage or 1
    local damage_type = props.damage_type or "magic"

    local target = enemy:choose_target()
    local projectile = map:create_custom_entity{
      x=x, y=y, layer=z, width = 16, height = 16, direction = 0,
      sprite = "entities/enemy_projectiles/vengeful_spirit",
      model = "enemy_projectiles/general_attack",
    }
    function projectile:pop() --removal animation/sound
      projectile:stop_movement()
      projectile:get_sprite():set_animation("explosion", function()
        projectile:remove()
      end)
      projectile:make_sound("enemies/vengeful_spirit_explode")
    end
    projectile.damage = damage
    projectile.damage_type = damage_type
    projectile.hit_callback = function()
      projectile:pop()
    end
    --sound:
    projectile:make_sound("enemies/vengeful_spirit_summon_short")
    --particle fx:
    local em = map:create_particle_emitter(x, y, z, "smoke")
    em.target = projectile
    em.angle = math.pi / 2
    em.angle_variance = 0
    em.particle_sprite = "effects/smoke_clouds"
    em.particle_speed = 35
    em.particles_per_loop = 1
    em.particle_opacity = {100,255}
    em.particle_fade_speed = 5
    em.particle_animation_loops = false
    em.particle_color = {255,230, 190}
    em.particle_scaling = {1, 1}
    em:emit()
    --burst up:
    local m = sol.movement.create"straight"
    m:set_angle(math.rad(math.random(45, 135)))
    m:set_speed(200)
    m:set_ignore_obstacles(true)
    m:start(projectile)
    --acceleration:
    sol.timer.start(projectile, 10, function()
      local cur_speed = m:get_speed()
      if cur_speed > 10 then
        m:set_speed(cur_speed - 5)
        return true
      end
    end)
    --target player:
    sol.timer.start(projectile, 1000, function()
      projectile:stop_movement()
      local m = sol.movement.create"straight"
      m:set_speed(projectile_speed)
      m:set_angle(projectile:get_angle(target))
      m:start(projectile)
      --track:
      local elapsed_tracking_time = 0
      sol.timer.start(projectile, track_frequency, function()
        local angle = m:get_angle()
        local target_angle = projectile:get_angle(target)
        local diff = math.abs(target_angle - angle)
        if diff < math.rad(track_step) then return true end --don't adjust if we're basically on track
        if target_angle < angle then track_step = track_step * -1 end
        if diff > math.pi then track_step = track_step * -1 end
        angle = angle + math.rad(track_step)
        angle = angle % (math.pi * 2)
        m:set_angle(angle)
        elapsed_tracking_time = elapsed_tracking_time + track_frequency
        return (elapsed_tracking_time < track_duration)
      end)
      --don't last forever:
      sol.timer.start(projectile, projectile_lifetime, function()
        projectile:pop()
      end)
    end)
    
  end
end


return manager
