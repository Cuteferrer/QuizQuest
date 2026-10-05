local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()


  local function choose_spot(range)
    local x,y,z = enemy:get_position()
    local dx, dy
    dx = math.random(range * -1, range)
    dy = math.random(range * -1, range)
    while enemy:test_obstacles(dx, dy) do
      dx = math.random(range * -1, range)
      dy = math.random(range * -1, range)
    end
    return x + dx, y + dy
  end


  function enemy:warp_away(props)
    props = props or {}
    local sprite = enemy:get_sprite()
    local range = props.range or 150
    local warping_duration = props.warping_duration or 1000
    local warping_out_animation = props.warping_out_animation or "warping"
    local warping_in_animation = props.warping_in_animation or "warping_in"
    local warp_out_sound = props.warp_out_sound
    local warp_in_sound = props.warp_in_sound
    local choose_spot_override = props.choose_spot_override
    local callback = props.callback or function() enemy:decide_action() end
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    enemy:set_invincible()
    if sprite:has_animation"invisible" then sprite:set_animation"invisible" end
    enemy:set_visible(false)
    local x,y,z = enemy:get_position()
    local direction = sprite:get_direction()
    local vanishing_entity = map:create_custom_entity{
      x=x, y=y, layer=z, direction=direction, width=16, height=16, sprite=enemy:get_sprite():get_animation_set()
    }
    vanishing_entity:get_sprite():set_animation(warping_out_animation, function()
      vanishing_entity:remove()
    end)
    if warp_out_sound then enemy:make_sound(warp_out_sound) end
    --enemy:set_position(choose_spot(range))
    local m = sol.movement.create"target"
    local tx, ty = choose_spot(range)
    if choose_spot_override then tx, ty = choose_spot_override() end
    m:set_target(tx, ty)
    m:set_speed(900)
    m:start(enemy)
    sol.timer.start(enemy, warping_duration, function()
      enemy:stop_movement()
      if warp_in_sound then enemy:make_sound(warp_in_sound) end
      local x,y,z = enemy:get_position()
      local appearing_entity = map:create_custom_entity{
        x=x, y=y, layer=z, direction=direction, width=16, height=16, sprite=enemy:get_sprite():get_animation_set()
      }
      appearing_entity:get_sprite():set_animation(warping_in_animation, function()
        sprite:set_animation"walking"
        enemy:set_visible()
        enemy:set_default_attack_consequences()
        vanishing_entity:remove()
        callback()
      end)
    end)
  end
end

return manager
