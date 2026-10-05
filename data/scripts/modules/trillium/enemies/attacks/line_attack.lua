local manager = {}

function manager.apply_behavior(enemy)

  function enemy:line_attack(props)
    local map = enemy:get_map()

    local windup_animation = props.windup_animation or "stopped"
    local windup_sound = props.windup_sound
    local windup_duration = props.windup_duration or 1000
    local attack_animation = props.attack_animation
    local attack_sprite = props.attack_sprite or "entities/enemy_projectiles/dust_attack"
    local attack_sprite_animation = props.attack_sprite_animation
    local attack_sound = props.attack_sound
    local attack_collision_delay = props.attack_collision_delay or 0 --how long before the bursting attack has collision to do damage
    local damage = props.damage or 1
    local damage_type = props.damage_type
    local hit_callback = props.hit_callback
    local recovery_duration = props.recovery_duration or 500
    local recovery_animation = props.recovery_animation or "stopped"
    local range = props.range or 200
    local frequency = props.frequency or 100
    local speed = props.speed or 300
    local start_sound = props.start_sound
    local screenshake_amount = props.screenshake_amount
    local callback = props.callback or function() enemy:decide_action() end
    local angle_override = props.angle_override
    local allowed_grounds = props.allowed_ground or {"traversable", "shallow_water", "grass", "ice", "ladder", }
    local origin_override = props.origin_override --allows to pass a table {x = 100, y = 456, layer = 0} to override where the attack originates from

    for _, gnd in pairs(allowed_grounds) do
      allowed_grounds[gnd] = true
    end

    local function make_attack_entity(x, y, z)
      local ground = map:get_ground(x, y, z)
      if not allowed_grounds[ground] then return end
      local attack = map:create_custom_entity{
        x=x, y=y, layer=z, direction = 0, width = 16, height = 16,
        sprite = attack_sprite,
        model = "enemy_projectiles/general_attack",
      }
      attack.parent_enemy = enemy
      attack:set_drawn_in_y_order(true)
      attack.delay_collision = true
      attack.damage = damage
      attack.damage_type = damage_type
      attack:remove_after_animation()
      attack.must_overlap = true
      if attack_sound then
        sol.audio.play_sound(attack_sound)
      end
      if hit_callback then attack.hit_callback = hit_callback end
      sol.timer.start(attack, attack_collision_delay, function()
        attack:activate_collision()
      end)
    end


    local target = enemy.target_entity or enemy:choose_target()
    local sprite = enemy:get_sprite()
    local direction = enemy:get_facing_direction_to(target)
    sprite:set_animation(windup_animation)
    sprite:set_direction(direction)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sol.timer.start(enemy, windup_duration, function()
      local x, y, z = enemy:get_position()
      if origin_override then
        x = origin_override.x or x
        y = origin_override.y or y
        z = origin_override.layer or z
      end
      local angle = enemy:get_angle(target)
      if angle_override then angle = angle_override end
      local direction = enemy:get_facing_direction_to(target)

      sprite:set_direction(direction)
      sprite:set_animation(attack_animation, function()
        sprite:set_animation(recovery_animation)
        sol.timer.start(enemy, recovery_duration, function()
          callback()
        end)
      end)
      if start_sound then
        sol.audio.play_sound(start_sound)
      end
      if screenshake_amount then
        map:screenshake({shake_count = screenshake_amount})
      end
      local target = map:create_custom_entity{x=x, y=y, layer=z, direction=0, width = 16, height=16, }
      local m = sol.movement.create"straight"
      m:set_ignore_obstacles(true)
      m:set_speed(speed)
      m:set_angle(angle)
      m:set_max_distance(range)
      m:start(target, function() target:remove() end)
      local elapsed_time = 0
      sol.timer.start(target, frequency, function()
        elapsed_time = elapsed_time + frequency
        local x, y, z = target:get_position()
        make_attack_entity(x, y, z)
        if (elapsed_time/1000 * speed <= range) then return frequency end
      end)

    end)

  end
end


return manager
