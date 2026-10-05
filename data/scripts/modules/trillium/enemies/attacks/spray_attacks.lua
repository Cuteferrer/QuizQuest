local manager = {}


function manager.apply_behavior(enemy)

  function enemy:ichor_spray(props)
    props = props or {}
    local windup_duration = props.windup_duration or 500
    local windup_animation = props.windup_animation or "ichor_spray"
    local windup_sound = props.windup_sound or "bugs_skittering"
    local attack_animation = props.attack_animation or "ichor_spray"
    local shot_frequency = props.shot_frequency or 300
    local num_shots = props.num_shots or 8
    local angle_variance = props.angle_variance or 45
    local shot_range = props.shot_range or 104
    local range_variance = props.range_variance or 32
    local shoot_sound = props._shoot_sound or "ichor_squish_01"
    local blob_sprite = props.blob_sprite or "entities/enemy_projectiles/ichor_blob"
    local blob_damage = props.damage or 10
    local blob_speed = props.blob_speed or 160
    local recovery_animation = props.recovery_animation or "stopped"
    local recovery_duration = props.recovery_duration or 600
    local map = enemy:get_map()
    local target = enemy:choose_target()

    local sprite = enemy:get_sprite()
    local aim_angle = enemy:get_angle(target)
    sprite:set_direction(enemy:get_facing_direction_to(aim_angle))

    local function shoot_blob()
      local x, y, z = enemy:get_position()
      sol.audio.play_sound(shoot_sound)
      local blob = map:create_custom_entity{
        x=x, y=y, layer=z, direction=0, width=8, height=8,
        sprite = blob_sprite,
        model = "enemy_projectiles/generic_projectile",
      }
      blob.damage = blob_damage
      blob.speed = blob_speed
      blob.max_distance = shot_range - math.random(0, range_variance)
      blob.obstacle_callback = function(projectile)
        local x, y, z = projectile:get_position()
        projectile:remove()
        map:create_custom_entity{
          x = x, y = y, layer = z, direction = 0, width = 16, height = 16,
          model = "enemy_projectiles/floor_blast",
          sprite = "entities/enemy_projectiles/eldritch_puddle_burst",
        }
      end
      blob:shoot(aim_angle + math.rad(math.random(angle_variance * -1, angle_variance)))
    end

    enemy:stop_movement()
    sprite:set_animation(windup_animation)
    enemy:make_sound(windup_sound)
    enemy:make_sound"ichor_splash"
    --Attack animation:
    sol.timer.start(enemy, windup_duration, function()
      sprite:set_animation(attack_animation)
    end)
    --Shoot blobs:
    local blob_count = 0
    sol.timer.start(enemy, windup_duration, function()
      shoot_blob()
      blob_count = blob_count + 1
      if blob_count < num_shots then
        return shot_frequency
      else
        sprite:set_animation(recovery_animation)
        sol.timer.start(enemy, recovery_duration, function() enemy:decide_action() end)
      end
    end)
  end


end

return manager
