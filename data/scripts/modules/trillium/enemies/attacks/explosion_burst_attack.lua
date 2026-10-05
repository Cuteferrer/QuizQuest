local manager = {}

function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  function enemy:explosion_burst_attack(props)
    local windup_duration = props.windup_duration or 500
    local windup_animation = props.windup_animation or "thrust_windup"
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation or "thrust_attack"
    local attack_sound = props.attack_sound
    local burst_sprite = props.burst_sprite or "hero_projectiles/silver_burst"
    local range = props.range or 32
    local num_bursts = props.num_bursts or 3
    local delay_min, delay_max = 50,150 --slightly offset burst timing
    local spread = props.spread or math.rad(60)
    local damage = props.damage or 1
    local damage_type = props.damage_type or "physical"
    local step_distance = props.step_distance or 8
    local recovery_animation = props.recovery_animation or "stopped"
    local recovery_duration = props.recovery_duration or 1200

    local sprite = enemy:get_sprite()
    local x, y, z = enemy:get_position()
    local target = enemy:choose_target()

    sprite:set_animation(windup_animation)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sol.timer.start(enemy, windup_duration, function()
      --face target:
      sprite:set_direction(enemy:get_facing_direction_to(target))
      --movement:
      if step_distance > 0 then
        local m = sol.movement.create"straight"
        m:set_angle(sprite:get_direction() * (math.pi / 2))
        m:set_speed(120)
        m:set_max_distance(step_distance)
        m:start(enemy)
      end
      --animation:
      sprite:set_animation(attack_animation, recovery_animation)
      --create bursts:
      local angle = enemy:get_angle(target)

      for i = 1, num_bursts do
        local da = (angle - spread / 2) + ((spread / num_bursts) * i)
        local dx = x + range * math.cos(da)
        local dy = ( y + range * math.sin(da) * -1 )
        sol.timer.start(map, math.random(delay_min, delay_max) * (i - 1), function()
          if attack_sound then sol.audio.play_sound(attack_sound) end
          local burst = map:create_custom_entity{
            x=dx, y=dy, layer=z, width = 8, height = 8, direction = 0,
            model = "enemy_projectiles/general_attack",
            sprite = burst_sprite,
          }
          burst.damage = damage
          burst.damage_type = damage_type
          burst:remove_after_animation()
        end)
      end
      sol.timer.start(enemy, recovery_duration, function()
        enemy:decide_action()
      end)
    end)
  end

end


return manager
