local manager = {}
local soundsets = require("scripts/modules/trillium/enemies/attacks/soundsets")

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  function enemy:melee_attack(props)
    local sprite = enemy:get_sprite()
    local windup_duration = props.windup_duration or 500
    local windup_animation = props.windup_animation
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation
    local attack_duration = props.attack_duration --for attacks with a looping animation, set a duration
    local recovery_animation = props.recovery_animation or "stopped"
    local weapon_sprite = props.weapon_sprite
    local weapon_windup_animation = props.weapon_windup_animation
    local weapon_attack_animation = props.weapon_attack_animation
    local collision_callback = props.collision_callback
    local attack_sound = props.attack_sound
    local attack_sounds = props.attack_sounds --can pass a table here, all sounds will be played
    local attack_soundset = props.attack_soundset
    local attacking_callback = props.attacking_callback --allows for a callback whenever the enemy attacks, whether or not it hits
    local damage = props.damage or 1
    local damage_type = props.damage_type or "physical"
    local has_aoe = props.has_aoe or false
    local ragdoll_distance = props.ragdoll_distance or false
    local turn_toward_hero = props.turn_toward_hero if props.turn_toward_hero == nil then turn_toward_hero = true end
    local step_distance = props.step_distance
    local step_speed = props.step_speed or 80
    local step_tracking = props.step_tracking or false
    local recovery_duration = props.recovery_duration or 500
    local next_action = props.next_action or (function() enemy:decide_action() end)
    local target = enemy.target_entity or enemy:choose_target()

    local function step_forward(direction, attack_entity)
      local angle = enemy:get_angle_from_facing_direction(direction)
      local step_angle = enemy:get_angle_from_facing_direction(angle)
      if step_tracking then
        step_angle = enemy:get_angle(target)
        sprite:set_direction(enemy:get_facing_direction_to(step_angle))
        attack_entity:set_direction(enemy:get_facing_direction_to(step_angle))
      end
      local m = sol.movement.create"straight"
      m:set_angle(step_angle)
      m:set_speed(step_speed)
      m:set_max_distance(step_distance)
      m:start(enemy)

      function m:on_position_changed(x, y, z)
        --move attack entity to stay on top of enemy
        y = y + (attack_entity.y_sorting_offset or 0)
        attack_entity:set_position(x, y, z)
        attack_entity:set_direction(sprite:get_direction())
      end
    end
    local x, y, z = enemy:get_position()
    local direction = enemy:get_facing_direction_to(target)
    if not turn_toward_hero then direction = sprite:get_direction() end
    local y_sorting_offset = direction == 1 and -1 or 1
    if enemy.sprite_direction_style == "horizontal" or enemy.sprite_direction_style == "single" then y_sorting_offset = 1 end
    --enemy:stop_movement()
    sprite:set_direction(direction)
    sprite:set_animation(windup_animation)
    local attack_entity = map:create_custom_entity{
      x = x, y = y + y_sorting_offset, layer = z, direction = direction,
      width = 16, height = 16,
      name = "enemy_melee_attack",
    }
    attack_entity.y_sorting_offset = y_sorting_offset
    attack_entity:set_drawn_in_y_order(true)
    enemy.attack_entities[attack_entity] = attack_entity
    local attack_sprite = weapon_windup_animation and attack_entity:create_sprite(weapon_sprite) or nil
    if attack_sprite then
      attack_sprite:set_animation(weapon_windup_animation)
      attack_sprite:set_direction(direction)
    end
    if windup_sound then sol.audio.play_sound(windup_sound) end

    --Wait for windup, then attack!:
    sol.timer.start(enemy, windup_duration, function()
      --Play sound
      local attack_sfx
      if attack_sound then
        attack_sfx = attack_sound
      elseif attack_sounds then
        for _, sound in pairs(attack_sounds) do sol.audio.play_sound(sound) end
      elseif attack_soundset then
        local soundset = soundsets[attack_soundset]
        attack_sfx = soundset[math.random(1, #soundset)]
      else --if neither sound or soundset specified, use default soundset
        local soundset = soundsets.default
        attack_sfx = soundset[math.random(1, #soundset)]
      end
      if attack_sfx then sol.audio.play_sound(attack_sfx) end
      sprite:set_animation(attack_animation, function() sprite:set_animation(recovery_animation) end)
      if attacking_callback then attacking_callback() end
      if attack_duration then sol.timer.start(enemy, attack_duration, function() sprite:set_animation(recovery_animation) end) end
      --Step into attack to close distance:
      if step_distance then step_forward(direction, attack_entity) end
      if weapon_attack_animation and not weapon_windup_animation then --we haven't yet created a sprite if it didn't have a windup animation
        attack_sprite = attack_entity:create_sprite(weapon_sprite)
        attack_sprite:set_direction(direction)
      end
      if weapon_attack_animation then
        attack_sprite:set_animation(weapon_attack_animation)
      end
      --Collision:
      local collided_entities = {}
      attack_entity:add_collision_test("sprite", function(attack_entity, other)
        local other_type = other:get_type()
        if collided_entities[other] then
          --nothing, can't hit twice
        elseif (other_type == "hero" or other_type == "enemy") and enemy:can_target(other) then
          collided_entities[other] = true
          if other.process_hit then
            other:process_hit({damage = damage, enemy = enemy, damage_type = damage_type})
          elseif other_type == "hero" then
            other:start_hurt(enemy, damage)
          end
          if ragdoll_distance and other.ragdoll then
            other:ragdoll(enemy:get_angle(other), ragdoll_distance)
          end
          if collision_callback then collision_callback(other) end
        end
      end)

      if has_aoe then
        enemy:create_melee_aoe(props)
      end

      if not attack_duration then
        attack_duration = sprite:get_num_frames(attack_animation, direction) * sprite:get_frame_delay(attack_animation) + recovery_duration
      end
      sol.timer.start(enemy, attack_duration, function()
        enemy.attack_entities[attack_entity]:remove()
        next_action()
      end)
    end)
  end


  function enemy:create_melee_aoe(props)
    local sprite_direction_style = enemy.sprite_direction_style or "normal"
    local aoe_offset = props.aoe_offset or 0
    local aoe_delay = props.aoe_delay or 200
    local aoe_sprite = props.aoe_sprite or "enemies/trillium_enemies/shockwave_8x7"
    local aoe_damage = props.aoe_damage or 1
    local aoe_sound = props.aoe_sound
    local aoe_screenshake = props.aoe_screenshake
    local aoe_scale = props.aoe_scale or {1, 1}

    local x, y, z = enemy:get_position()
    local direction = enemy:get_sprite():get_direction()
    sol.timer.start(map, aoe_delay, function()
      if aoe_sound then sol.audio.play_sound(aoe_sound) end
      if aoe_screenshake then map:screenshake({shake_count = aoe_screenshake}) end

      local shock_x = 0
      local shock_y = 0
      if sprite_direction_style == "horizontal" then
        if direction == 1 then
          shock_x = aoe_offset * -1
        else
          shock_x = aoe_offset
        end
      else
          shock_x = game:dx(aoe_offset)[direction]
          shock_y = game:dy(aoe_offset)[direction]
      end

      local shockwave = map:create_custom_entity{
        x = x + shock_x, y = y + shock_y + 1, layer = z,
        direction = 0, width = 16, height = 16,
        sprite = aoe_sprite,
      }
      if aoe_scale then shockwave:get_sprite():set_scale(aoe_scale[1], aoe_scale[2]) end
      local collided_entities = {}
      shockwave:add_collision_test("sprite", function(shockwave, other)
        local other_type = other:get_type()
        if collided_entities[other] then
          --nothing, can't hit twice
        elseif (other_type == "hero" or other_type == "enemy") and enemy:can_target(other) then
          collided_entities[other] = true
          if other.process_hit then
            other:process_hit{damage = aoe_damage, enemy = shockwave}
          elseif other_type == "hero" then
            other:start_hurt(enemy, damage)
          end
        end
      end)
    end)
  end



  function enemy:melee_combo(attacks)
    local new_attacks = {}
    for i, v in ipairs(attacks) do
      new_attacks[i] = {}
      for k, v in pairs(v) do new_attacks[i][k] = v end
    end
    for i = 1, #new_attacks - 1 do
      new_attacks[i].next_action = function()
        enemy:melee_attack(new_attacks[i + 1])
      end
    end
    enemy:melee_attack(new_attacks[1])
  end


end


return manager