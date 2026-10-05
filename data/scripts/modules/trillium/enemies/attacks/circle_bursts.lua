local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:get_sprite()

  function enemy:circle_bursts_attack(props)
    sprite = enemy:get_sprite()
    props = props or {}
    local damage = props.damage or 1 --NOTE: this just sets each attack_entity.damage = damage  , if the attack entity model you choose doesn't use that, it will do nothing
    local windup_animation = props.windup_animation or "magic_charging"
    local windup_duration = props.windup_duration or 500
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation or "magic_shooting"
    local attack_sound = props.attack_sound
    local attack_radius = props.attack_radius or 24
    local num_attacks = props.num_attacks or 8
    local attack_entity_model = props.attack_entity_model
    local attack_entity_sprite = props.attack_entity_sprite
    local attack_entity_width = props.attack_entity_width or 16
    local attack_entity_height = props.attack_entity_height or 16
    local attack_entity_direction = props.attack_entity_direction or 0
    local attack_entity_duration = props.attack_entity_duration
    local recovery_duration = props.recovery_duration or 1000

    enemy:stop_movement()
    sprite:set_animation(windup_animation)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sol.timer.start(enemy, windup_duration, function()
      sprite:set_animation(attack_animation, "walking")
      if attack_sound then sol.audio.play_sound(attack_sound) end
      local x,y,z = enemy:get_position()
      local attack_entities = {}
      for i = 1, num_attacks do
        local angle = 2 * math.pi / num_attacks * i
        local dx = attack_radius * math.cos(angle)
        local dy = attack_radius * math.sin(angle)
        attack_entities[i] = map:create_custom_entity{
          x = x + dx, y = y + dy, layer = z,
          width = attack_entity_width, height = attack_entity_height, direction = attack_entity_direction,
          model = attack_entity_model, sprite = attack_entity_sprite
        }
        if not attack_entity_model then
          attack_entities[i]:create_sprite("entities/enemy_projectiles/generic_projectile")
          attack_entities[i]:set_drawn_in_y_order(true)
          attack_entities[i]:add_collision_test("sprite", function(atk_ent, other)
            if other:get_type() == "hero" then
              attack_entities[i]:clear_collision_tests()
              other:start_hurt(1)
            end
          end)
        end
      end
      if attack_entity_duration then
        sol.timer.start(map, attack_entity_duration, function()
          for _, atk_ent in pairs(attack_entities) do atk_ent:remove() end
        end)
      end
      enemy:decide_action()
    end)

  end

end

return manager
