local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  function enemy:ranged_attack(props)
    local sprite = enemy:get_sprite()
    local windup_animation = props.windup_animation
    local windup_duration = props.windup_duration or 700
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation
    local projectile_model = props.projectile_model or "enemy_projectiles/generic_projectile"
    local generic_projectile_type = props.generic_projectile_type --Calls projectile:set_projectile_type()
    local aim_type = props.aim_type or "any" --options are 4, 8, or "any". Determines angle of projectile
    local aim_variance = props.aim_variance or 0
    local angle_override = props.angle_override --Allow to aim in some direction other than toward the target
    local num_projectiles = props.num_projectiles or 1
    local projectile_spread = math.rad(props.projectile_spread or 60)
    local projectile_sprite = props.projectile_sprite or "entities/enemy_projectiles/generic_projectile"
    local projectile_animation = props.projectile_animation
    local projectile_width = props.projectile_width or 16
    local projectile_height = props.projectile_height or 16
    local projectile_offset_radius = props.projectile_offset_radius or 16 --how far out from the enemy's origin the projectile spawns, depending on facing direction
    local projectile_offset_x = props.projectile_offset_x or 0 --when facing up/down, how far to the left/right we'll offset. Inverts when facing up vs down (i.e. 8 becomes -8)
    local projectile_offset_y = props.projectile_offset_y or 0 --when facing right/left, how far up/down we'll offset
    local projectile_properties = props.projectile_properties or {} --sets at least damage, speed, and range
    local sprite_y_offset = props.sprite_y_offset or -12
    local tracking = props.tracking
    local tracking_step = props.tracking_step
    local attack_sound = props.attack_sound or "throw"
    local damage = props.damage or 1
    local damage_type = props.damage_type or "bullet"
    local recovery_duration = props.recovery_duration or 500
    local recovery_animation = props.recovery_animation
    local next_action = props.next_action or enemy.decide_action

    local target = enemy:choose_target()

    enemy:stop_movement()
    local x, y, z = enemy:get_position()
    local direction = enemy:get_facing_direction_to(target)
    sprite:set_direction(direction)
    sprite:set_animation(windup_animation)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sol.timer.stop_all(enemy)
    --track hero during windup:
    local turning_timer = sol.timer.start(enemy, 100, function()
      direction = enemy:get_facing_direction_to(target)
      sprite:set_direction(direction)
      return true
    end)
    sol.timer.start(enemy, windup_duration, function()
      turning_timer:stop()
      direction = enemy:get_facing_direction_to(target)
      sprite:set_direction(direction)
      if attack_animation then
        sprite:set_animation(attack_animation, function()
          if recovery_animation then
            sprite:set_animation(recovery_animation, "stopped")
          else
            sprite:set_animation"stopped"
          end
        end)
      elseif recovery_animation then
        sprite:set_animation(recovery_animation, "stopped")
      else
        sprite:set_animation("stopped")
      end
      local step = projectile_offset_radius
      local dx = {[0] = step, [1]=0 + projectile_offset_x, [2]= step * -1, [3]=0 - projectile_offset_x}
      local dy = {[0]= projectile_offset_y, [1] = step * -1, [2]= projectile_offset_y, [3]= step}

      local projectile_direction = enemy:get_direction4_to(target)
      for i = 1, num_projectiles do
        local projectile = map:create_custom_entity{
          x = x + dx[projectile_direction],
          y = y + dy[projectile_direction],
          layer = z,
          width = projectile_width, height = projectile_height, direction = projectile_direction, 
          model = projectile_model, sprite = projectile_sprite,
        }
        --Set various attack properties:
        projectile.damage = damage
        projectile.damage_type = damage_type
        if projectile_sprite then
          projectile:create_sprite(projectile_sprite)
          projectile:remove_sprite()
        end
        local projectile_sprite = projectile:get_sprite()
        if projectile_sprite then
          projectile_sprite:set_xy(0, sprite_y_offset)
        end
        if projectile_animation then projectile:get_sprite():set_animation(projectile_animation) end
        projectile.firing_entity = enemy
        if tracking then
          projectile.tracking_target = target
          projectile.tracking_step = tracking_step
        end
        --Set generic projectile type (the generic projectile model has some presets)
        if generic_projectile_type then
          projectile:set_projectile_type(generic_projectile_type)
        end
        --Set arbitrary properties to the projectile (note, this could overwrite damage)
        for k, v in pairs(projectile_properties) do
          projectile[k] = v
        end
        local aim_angle
        if aim_type == "any" then
          aim_angle = projectile:get_angle(target)
        elseif aim_type == 4 then
          aim_angle = projectile_direction * math.pi / 2
        elseif aim_type == 8 then
          aim_angle = projectile:get_direction8_to(target) * math.pi / 4
        end
        --Allow for some poor aim:
        aim_angle = aim_angle + math.rad( math.random(aim_variance * -1, aim_variance) )
        local shoot_angle
        if num_projectiles <= 1 then
          shoot_angle = aim_angle
        else
          shoot_angle = aim_angle - (projectile_spread / 2) + (projectile_spread / num_projectiles * i)
        end
        if angle_override then shoot_angle = angle_override end
        projectile:shoot(shoot_angle)
      end

      sol.audio.play_sound(attack_sound)
      sol.timer.start(enemy, recovery_duration, function()
        next_action()
      end)
    end)

  end



  function enemy:ranged_combo(attacks)
    local new_attacks = {}
    for i = 1, #attacks do
      new_attacks[i] = {}
      for k, v in pairs(attacks[i]) do new_attacks[i][k] = v end
    end
    for i = 1, #new_attacks - 1 do
      new_attacks[i].next_action = function()
        enemy:ranged_attack(new_attacks[i + 1])
      end
    end
    enemy:ranged_attack(new_attacks[1])
  end


end


return manager