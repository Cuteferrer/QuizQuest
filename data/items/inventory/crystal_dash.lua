local item = ...
local game = item:get_game()

local magic_lock_amount = 30 --if you don't have this much magic in the tank, you can't start the spell. This ensures you have a minimum distance you can travel, rather than just rocketing 8px then being out of magic.
local magic_consumption_rate = 40 --how often (in ms) magic_consumption_amount is consumed
local magic_consumption_amount = 1 --magic consumption is smoothest if this is kept at 1
local charge_time = 1000
local dash_speed = 400
local damage = 6
local control_sensitivity = 15 --every X ms, can control movement by 1 px Shorter gives you more control. So will a slower dash speed.
local control_step = 1 --number of pixels per control_sensitivity moved. More than 1 looks weird, but hey, it's a setting to tweak.

function item:on_started()
  item:set_savegame_variable("possession_crystal_dash")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()
  if game:get_magic() < magic_lock_amount then
    item:set_finished()
    return
  end
  if hero:get_state() == "custom" and (hero:get_state_object():get_description() == "crystal_dashing") then
    return
  elseif hero:get_state() == "custom" and (hero:get_state_object():get_description() == "charging") then
    hero.crystal_dash_charge_timer:stop()
    item:set_finished()
  end

  local charging_state = item:get_charging_state()
  hero:start_state(charging_state)
  hero:set_animation"charging"
  local charging_sprite = hero:create_sprite("items/wind_charge", "wind_charge")
  charging_sprite:set_opacity(150)
  hero.crystal_dash_charge_timer = sol.timer.start(charging_state, charge_time, function()
    --Begin Dash
    local x, y, z = hero:get_center_position()
    local explosion = map:create_custom_entity{
      x=x, y=y+1, layer=z, width=16, height=16, direction=0, sprite="items/white_energy_explosion", model = "ephemeral_effect",
    }
    explosion:set_drawn_in_y_order(true)
    hero:remove_sprite(charging_sprite)
    hero.crystal_dashing = true
    hero:set_animation"flying"
    local state = item:get_dashing_state()
    hero:start_state(state)
    local dashing_sprite = hero:create_sprite("items/crystal_dash")
    dashing_sprite:set_direction(hero:get_direction())
    hero:bring_sprite_to_back(dashing_sprite)
    local size = 32
    local attack_entity = map:create_custom_entity{
      x=x, y=y, layer=z, width=size, height=size, direction=0,
    }
    attack_entity:set_origin(size/2, size/2)
    attack_entity:add_collision_test("overlapping", function(attack_entity, other)
      if other:get_type() == "enemy" then
        other:hurt(damage)
      end
    end)
    local m = sol.movement.create"straight"
    m:set_angle(hero:get_direction() * math.pi / 2)
    m:set_speed(dash_speed)
    m:start(hero)
    function m:on_obstacle_reached()
      sol.audio.play_sound"running_obstacle"
      map:get_camera():shake()
      hero:unfreeze()
    end

    function state:on_position_changed()
      local x, y, z = hero:get_center_position()
      attack_entity:set_position(x, y, z)
    end

    function state:on_finished()
      hero:remove_sprite(dashing_sprite)
      attack_entity:remove()
      if item.magic_consumption_timer then item.magic_consumption_timer:stop() end
    end

    function state:on_command_pressed(cmd)
      if (cmd == "action") or (cmd == "attack") or (cmd == "item_1" ) or (cmd == "item_2") then
        hero:stop_movement()
        sol.timer.start(hero, 100, function()
          hero:unfreeze()
        end)
      end
    end

    --allow for slight directional control
    sol.timer.start(state, control_sensitivity, function()
      local x, y, z = hero:get_position()
      if game:is_command_pressed("right") then hero:set_position(x + control_step, y) end
      if game:is_command_pressed("up") then hero:set_position(x, y - control_step) end
      if game:is_command_pressed("left") then hero:set_position(x - control_step, y) end
      if game:is_command_pressed("down") then hero:set_position(x, y + control_step) end
      return true
    end)

    --eat up magic as you go
    item.magic_consumption_timer = sol.timer.start(hero, magic_consumption_rate, function()
      game:remove_magic(magic_consumption_amount)
      if game:get_magic() <= 0 then
        hero:unfreeze()
      else
        return true
      end
    end)

  end)
  function charging_state:on_finished()
    if hero:get_sprite("wind_charge") then
      hero:remove_sprite(charging_sprite)
    end
    hero.crystal_dash_charge_timer:stop()
  end

end


function item:get_charging_state()
  local state = sol.state.create("charging")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(false)
  state:set_can_use_stream(false)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")
  return state
end


function item:get_dashing_state()
  local state = sol.state.create("crystal_dashing")
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("lava", true)
  state:set_affected_by_ground("hole", false)
  state:set_affected_by_ground("deep_water", false)
  state:set_affected_by_ground("lava", false)
  state:set_gravity_enabled(false)
  state:set_can_come_from_bad_ground(false)
  state:set_can_be_hurt(false)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(false)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(false)
  state:set_can_use_stream(false)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")
  return state
end


