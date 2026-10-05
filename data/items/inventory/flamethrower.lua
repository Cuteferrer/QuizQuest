local item = ...
local game = item:get_game()

local magic_cost = 3
local startup_cost = 20 --magic cost is how much magic per check frequency. It uses a larger amount to get started than to maintain
local SPEED_DELTA = 40 --how much slower the hero walks while using the flamethrower
local flame_spread = 30 --spread of flames in degrees off of axis
local flame_speed = 60
local flame_generation_frequency = 100 --frequency in ms that flames are generated
local magic_check_frequency = 200
local burn_duration = 100

function item:on_started()
  item:set_savegame_variable("possession_flamethrower")
  item:set_assignable(true)
  item:set_ammo("_magic")
end

function item:on_using()
  if (item:get_ammo() >= startup_cost) and not item.active then
    item.active = true
    item:activate()
  elseif item:get_ammo() < startup_cost then
    sol.audio.play_sound"door_closed"
    item:set_finished()
  else
    item.active = false
    item:deactivate()
  end
end


function item:activate()
  item.active = true
  local hero = game:get_hero()
  local map = game:get_map()
  hero:set_animation"flamethrower"
  hero:start_state(item:get_flamethrower_state())
  item.flame_gen_timer = sol.timer.start(hero, 0, function()
    local x, y, z = hero:get_position()
    local direction = hero:get_direction()
    local dx = game:dx(16)
    local dy = game:dy(16)
    local flame = map:create_fire{
      x=x + dx[direction], y=y + dy[direction], layer=z,
      properties = {{key = "burn_duration", value = burn_duration}}
    }
    flame.harmless_to_hero = true
    local m = sol.movement.create"straight"
    m:set_angle(direction * math.pi / 2 + math.rad( math.random(-20, 20) ) )
    m:set_speed(flame_speed)
    m:start(flame)
    return flame_generation_frequency
  end)
  item.magic_check_timer = sol.timer.start(hero, 0, function()
    if item:try_spend_ammo(magic_cost) then
      return magic_check_frequency
    else
      item:deactivate()
    end
  end)
end


function item:deactivate()
  item.active = false
  local hero = game:get_hero()
  item.flame_gen_timer:stop()
  item.magic_check_timer:stop()
  sol.timer.start(hero, 10, function() --need this delay for some reason, idk why
    item:set_finished()
    hero:unfreeze()
  end)
end



function item:get_flamethrower_state()
  local hero = game:get_hero()
  local state = sol.state.create()
  state:set_description("flamethrower")
  state:set_visible(true)
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
  state:set_gravity_enabled(true)
  state:set_can_come_from_bad_ground(true)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_shield(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(true)
  state:set_can_use_stream(true)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")

  function state:on_started()
    hero:set_walking_speed(hero:get_walking_speed() - SPEED_DELTA)
  end

  function state:on_finished()
    hero:set_walking_speed(hero:get_walking_speed() + SPEED_DELTA)
    if item.active then
      item:deactivate()
    end
  end

  function state:on_command_pressed(cmd)
    if cmd == "item_1" or cmd == "item_2" or cmd == "action" or cmd == "attack" then
      item:deactivate()
    end
  end

  return state
end
