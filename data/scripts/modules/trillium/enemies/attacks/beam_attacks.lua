local manager = {}

function manager.apply_behavior(enemy)

  --Normalize angle
  function normalize_angle(angle)
    return ((angle + math.pi) % (2 * math.pi)) - math.pi
  end

  function enemy:create_beam(props)
    props = props or {}
    local beam_sprite = props.beam_sprite or  "entities/enemy_projectiles/silver_beam"
    local beam_animation = props.beam_animation or "long"
    local beam_scale = props.beam_scale or {1,1}
    local damage = props.damage or 10
    local damage_type = props.damage_type or "magic"
    local damage_frequency = props.damage_frequency or 300
    local beam_in_front = props.beam_in_front or false
    local beam_sprite_offset = props.beam_offset or {0,0}

    local map = enemy:get_map()
    local x, y, z = enemy:get_position()
    local dy = beam_in_front and 1 or -1
    local beam = map:create_custom_entity{
      x=x, y=y + dy, layer=z, width=16, height=16, direction=0,
      model = "enemy_projectiles/general_attack",
      sprite = beam_sprite,
    }
    beam_sprite = beam:get_sprite()
    beam_sprite:set_animation(beam_animation)
    beam_sprite:set_scale(beam_scale[1], beam_scale[2])
    beam_sprite:set_xy(beam_sprite_offset[1], beam_sprite_offset[2])
    beam.damage= damage
    beam.damage_frequency = damage_frequency
    beam.damage_type = damage_type
    beam.delay_collision = true
    sol.timer.start(beam, 300, function() beam:activate_collision() end)

    return beam
  end



  function enemy:beam_spin_attack(props)
    props = props or {}
    local num_beams = props.num_beams or 2
    local rotation_speed = props.rotation_seed or 50 --this is the frequency how often the angle is updated, so bigger numbers are slower
    local rotation_step = props.rotation_step or 3
    local beam_lifespan = props.beam_lifespan or 4000
    local initial_angle = props.initial_angle or 0
    local callback = props.callback
    local recovery_duration = props.recovery_duration or 0

    for i = 1, num_beams do
      local angle = (i - 1) * (2 * math.pi / num_beams) + initial_angle
      local beam = enemy:create_beam(props)
      local beam_sprite = beam:get_sprite()
      beam_sprite:set_rotation(angle)
      sol.timer.start(beam, rotation_speed, function()
        angle = (angle + math.rad(rotation_step)) % (math.pi * 2)
        beam_sprite:set_rotation(angle)
        return true
      end)
      sol.timer.start(beam, beam_lifespan, function()
        beam:clear_collision_tests()
        beam_sprite:fade_out()
        sol.timer.start(beam, 1000, function() beam:remove() end)
      end)
      --Move beams with enemy:
      sol.timer.start(beam, 20, function()
        local x, y, z = enemy:get_position()
        beam:set_position(x, y-1, z)
        return true
      end)
    end 
    sol.timer.start(enemy, beam_lifespan, function()
      sol.timer.start(enemy, recovery_duration, function()
        if callback then
          callback()
        else
          enemy:decide_action()
        end
      end)
    end)
  end


  function enemy:targeted_laser_attack(props)
    props = props or {}
    local target = enemy:choose_target() or hero
    local targeting_speed = props.targeting_speed or 1
    local targeting_frequency = props.targeting_frequency or 10
    local beam = enemy:create_beam(props)
    local beam_sprite = beam:get_sprite()
    local radius = props.beam_length or 160 --how far away the tip of the beam is
    local attack_duration = props.attack_duration or 4000
    local callback = props.callback or function() enemy:decide_action() end
    local x, y, z = enemy:get_position()
    local map = enemy:get_map()
    
    local angle = (3 * math.pi / 2)
    beam_sprite:set_rotation(angle)
    --Smoke from beam impact:
    local em = map:create_particle_emitter(x, y, z, "smoke")
    em:emit()

    local pivot_timer = sol.timer.start(enemy, targeting_frequency, function()
      --While we're here, let's remove the beam if the enemy is killed:
      if enemy:get_life() <= 0 then beam:remove() return end
      local current_angle = normalize_angle(angle)
      local target_angle = normalize_angle(enemy:get_angle(target))
      local diff = (target_angle - current_angle) % 360
      local dir = (diff < math.pi) and 1 or -1
      if math.deg(diff) < 10 then return true end --don't change angle if it's basically already there
      angle = angle + (math.rad(targeting_speed) * dir)
      beam_sprite:set_rotation(angle)
      --Move smoke emitter:
      em:set_position(x + math.cos(angle) * radius, y + math.sin(angle) * radius * -1, z)
      return targeting_frequency
    end)

    sol.timer.start(map, attack_duration, function()
      pivot_timer:stop()
      beam:clear_collision_tests()
      beam_sprite:fade_out()
      sol.timer.start(beam, 1000, function()
        em:remove()
        beam:remove()
      end)
      callback()
    end)

  end



  function enemy:laser_blast(props)
    props = props or {}
    local attack_duration = props.attack_duration or 500
    local windup_duration = props.windup_duration or 400
    local windup_sound = props.windup_sound or "bot_charging"
    local windup_animation = props.windup_animation or "laser_charging"
    local attack_sound = props.attack_sound or "spells/silver_beam_burst"
    local attack_animation = props.attack_animation or "stopped"
    local recovery_duration = props.recovery_duration or 100
    local recovery_animation = props.recovery_animation or "stopped"
    local next_action = props.next_action or function() enemy:decide_action() end

    local sprite = enemy:get_sprite()
    local target = enemy:choose_target()

    sprite:set_direction(enemy:get_facing_direction_to(target))
    sol.audio.play_sound(windup_sound)
    sprite:set_animation(windup_animation)
    sol.timer.start(enemy, windup_duration, function()
      sprite:set_animation(attack_animation, function() sprite:set_animation(recovery_animation) end)
      local beam = enemy:create_beam(props)
      beam.delay_collision = true
      local beam_sprite = beam:get_sprite()
      beam_sprite:set_rotation(enemy:get_angle(target))
      beam_sprite:set_xy(0, -8)
      sol.audio.play_sound(attack_sound)

      sol.timer.start(beam, 360, function() beam:activate_collision() end)

      sol.timer.start(beam, attack_duration, function()
        beam:clear_collision_tests()
        beam_sprite:fade_out(5)
        sol.timer.start(beam, 1000, function()
          beam:remove()
        end)
        sol.timer.start(enemy, recovery_duration, function()
          next_action()
        end)
      end)
    end)
  end

end


return manager

