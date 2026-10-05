local manager = {}

function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  function enemy:howl_attack(props)
    assert(props.windup_animation, "Need to pass a windup animation")
    assert(props.attack_animation, "Need to pass an attack animation")
    local windup_animation = props.windup_animation
    local windup_duration = props.windup_duration or 1000
    local windup_sound = props.windup_sound
    local attack_animation = props.attack_animation
    local attack_duration = props.attack_duration or 2560 --Do in increments of 320ms to match animation best
    local attack_sound = props.attack_sound
    local attack_scale = props.attack_scale or {1, 1} --the sprite is 14x14 tiles (so a 112px radius on the attack), so scale accordingly depending how large you want your AOE to be
    local y_offset = props.y_offset or -32
    local damage = props.damage or 10
    local damage_frequency = props.damage_frequency or 300
    local damage_type = props.damage_type or "magic"
    local recovery_animation = props.recovery_animation or "stopped"
    local recovery_duration = props.windup_duration or 50
    local callback = props.callback or function() enemy:decide_action() end

    local sprite = enemy:get_sprite()
    sprite:set_animation(windup_animation)
    if windup_sound then sol.audio.play_sound(windup_sound) end
    sol.timer.start(enemy, windup_duration, function()
      if attack_animation then sprite:set_animation(attack_animation) end
      if attack_sound then sol.audio.play_sound(attack_sound) end
      --Create effect:
      local x, y, z = enemy:get_position()
      local aoe = map:create_custom_entity{
        x = x, y = y + y_offset, layer=z, width=16, height = 16, direction=0,
        sprite = "items/screamwave_14x14",
        model = "enemy_projectiles/general_attack",
      }
      aoe.damage= damage
      aoe.damage_frequency = damage_frequency
      aoe.damage_type = damage_type
      local aoe_sprite = aoe:get_sprite()
      aoe_sprite:set_scale(attack_scale[1], attack_scale[2])
      aoe_sprite:set_animation("starting")
      local function remove_aoe()
        aoe_sprite:set_animation("ending", function()
          aoe:remove()
        end)
      end
      --Duration:
      local aoe_timer = sol.timer.start(aoe, attack_duration, function()
        remove_aoe()
        sprite:set_animation(recovery_animation)
        sol.timer.start(enemy, recovery_duration, function()
          callback()
        end)
      end)
      --Check to remove early if killing enemy:
      sol.timer.start(map, 100, function()
        if enemy:get_life() > 0 then
          return true
        else
          aoe_timer:stop()
          remove_aoe()
        end
      end)
    end)
  end
end

return manager
