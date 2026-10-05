local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:get_sprite()

  function enemy:ram_attack(props)
    props = props or {}
    local damage = props.damage or enemy:get_damage() or 2
    local damage_type = props.damage_type or nil
    local orthogonal_ram = props.orthogonal_ram or false
    local angle_locked_at_windup = props.angle_locked_at_windup or false
    local speed = props.speed or 180
    local smooth = props.smooth or false
    local max_distance = props.max_distance or 100
    local windup_animation = props.windup_animation or "stopped"
    local windup_duration = props.windup_duration or 500
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation or "walking"
    local weapon_sprite = props.weapon_sprite
    local weapon_windup_animation = props.weapon_windup_animation
    local weapon_attack_animation = props.weapon_attack_animation
    local attack_sound = props.attack_sound
    local recovery_animation = props.recovery_animation
    local recovery_duration = props.recovery_duration or 300
    local obstacle_collision_callback = props.obstacle_collision_callback
    local hit_hero_callback = props.hit_hero_callback
    local finished_callback = props.finished_callback

    local target = enemy:choose_target()

    local sprite = enemy:get_sprite()
    local angle
    if angle_locked_at_windup then
      angle = orthogonal_ram and enemy:get_direction4_to(target) * math.pi / 2 or enemy:get_angle(target)
    end
    enemy:stop_movement()
    sprite:set_direction(enemy:get_facing_direction_to(target))
    sprite:set_animation(windup_animation)
    local x, y, z = enemy:get_position()
    local weapon_entity = map:create_custom_entity{
      x=x, y=y, layer=z, direction = sprite:get_direction(), width = 16, height = 16,
      sprite = weapon_sprite,
    }
    enemy.attack_entities[weapon_entity] = weapon_entity
    if weapon_windup_animation then
      weapon_entity:get_sprite():set_animation(weapon_windup_animation)
    else
      weapon_entity:set_visible(false)
    end
    function weapon_entity:on_update()
      weapon_entity:set_position(enemy:get_position())
      weapon_entity:get_sprite():set_direction(sprite:get_direction())
      if enemy:get_life() <= 0 then weapon_entity:remove() end
    end
    if windup_sound then sol.audio.play_sound(windup_sound) end

    --Timer before starting ram attack
    sol.timer.start(enemy, windup_duration, function()
      if not angle_locked_at_windup then
        angle = orthogonal_ram and enemy:get_direction4_to(target) * math.pi / 2 or enemy:get_angle(target)
      end
      if attack_sound then sol.audio.play_sound(attack_sound) end
      sprite:set_animation(attack_animation)
      weapon_entity:set_visible(true)
      --Add collision to the weapon entity now that we're attacking
      local collided_entities = {}
      weapon_entity:add_collision_test("sprite", function(weapon_entity, other)
        if collided_entities[other] then return end
        collided_entities[other] = true
        local other_type = other:get_type()
        if (other_type == "hero" or other_type == "enemy") and enemy:can_target(other) then
          if other.process_hit then
            other:process_hit({damage = damage, enemy = enemy, damage_type = damage_type})
          elseif other_type == "hero" then
            other:start_hurt(enemy, damage)
          end
          if hit_hero_callback then hit_hero_callback(other) end
        end
      end)
      weapon_entity:get_sprite():set_animation(weapon_attack_animation)
      local m = sol.movement.create"straight"
      m:set_angle(angle)
      m:set_speed(speed)
      m:set_smooth(smooth)
      m:set_max_distance(max_distance)
      m:start(enemy, function() enemy:finish_ram() end)
      function m:on_obstacle_reached()
        m.on_obstacle_reached = nil --prevent infinite calls
        if obstacle_collision_callback then
          weapon_entity:remove()
          obstacle_collision_callback()
        else
          enemy:finish_ram()
        end
      end

      function enemy:finish_ram()
        weapon_entity:remove()
        enemy:stop_movement()
        if recovery_duration then
          sprite:set_animation(recovery_animation or "stopped")
          sol.timer.start(enemy, recovery_duration, function()
            sprite:set_animation"stopped"
            if finished_callback then
              finished_callback()
            else
              enemy:decide_action()
            end
          end)
        else
          sprite:set_animation"stopped"
          enemy:decide_action()
        end
      end

    end)
  end

end

return manager
