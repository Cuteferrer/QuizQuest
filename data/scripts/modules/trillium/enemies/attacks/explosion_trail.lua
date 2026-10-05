local manager = {}

function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  function enemy:explosion_trail_attack(props)
    local windup_duration = props.windup_duration or 500
    local windup_animation = props.windup_animation or "stopped"
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation or "walking"
    local attack_sound = props.attack_sound
    local dash_duration = props.dash_duration or 1100
    local dash_speed = props.dash_speed or 240
    local frequency = props.frequency or 100
    local explosion_delay = props.explosion_delay or 700
    local damage = props.damage or enemy.base_damage or 1
    local damage_type = props.damage_type or "physical"
    local explosion_sound = props.explosion_sound or "explosion"
    local callback = props.callback or function() enemy:decide_action() end
    
    local target = enemy:choose_target()
    local sprite = enemy:get_sprite()
    local angle = enemy:get_angle(target)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sprite:set_animation(windup_animation)
    sol.timer.start(enemy, windup_duration, function()
      sprite:set_animation(attack_animation)
      if attack_sound then sol.audio.play_sound(attack_sound) end
      --Movement
      local m = sol.movement.create("straight")
      m:set_angle(angle)
      m:set_speed(dash_speed)
      m:set_smooth(false)
      m:start(enemy)
      sol.timer.start(enemy, dash_duration, function()
        enemy:stop_movement()
        callback()
      end)

      --Create explosions:
      local elapsed_time = 0
      sol.timer.start(enemy, frequency, function()
        elapsed_time = elapsed_time + frequency
        if elapsed_time > dash_duration then return end
        local x, y, z = enemy:get_position()
        --create "mine"
        local mine = map:create_custom_entity{
          x=x, y=y, layer=z, width = 8, height = 8, direction = 0,
          sprite = "entities/enemy_projectiles/silver_ball",
        }
        sol.timer.start(map, explosion_delay, function()
          mine:remove()
          sol.audio.play_sound(explosion_sound)
          local burst = map:create_custom_entity{
            x=x, y=y, layer=z, width = 8, height = 8, direction = 0,
            model = "enemy_projectiles/general_attack",
            sprite = "hero_projectiles/silver_burst",
          }
          burst.damage = damage
          burst.damage_type = damage_type
        end)
        return true
      end)
    end)

  end

end

return manager
