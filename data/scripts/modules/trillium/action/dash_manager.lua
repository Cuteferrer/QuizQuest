--[[
Created by Max Mraz, licensed MIT

Functions for rolling and dashing.
Default config at modules/trillium_config/dash_config

Usage:
hero:dash(props_overrides)

Changing dash level:
Dash level determines a bunch of properties like how far, how fast, animation, etc.
- game:set_dash_level(2)

There are a bunch of properties you can override by passing a config object. Here's what they are and what they're set to --
Note that most of them default to the values set in the config file

iframe_duration = props.iframe_duration or invincibility_lengths[dash_level]
dash_speed = props.speed or dash_speeds[dash_level]
dash_distance = props.distance or dash_distances[dash_level]
dash_animation = props.animation or dash_animations[dash_level]
dash_sound = props.sound or dash_sounds[dash_level][math.random(1, #dash_sounds[dash_level])]
angle_override = props.angle_override
create_dust = props.create_dust or true --also creates water ripples if rolling in shallow water
can_cross_hole = props.can_cross_hole or default_dash_cross_hole

--]]

local dash_config = require("scripts/modules/trillium_config/action/dash_config")
local hero_meta = sol.main.get_metatable"hero"
local game_meta = sol.main.get_metatable("game")

local dash_distances = dash_config.dash_distances
local dash_speeds = dash_config.dash_speeds
local dash_animations = dash_config.dash_animations
local dash_sounds = dash_config.dash_sounds
local invincibility_lengths = dash_config.invincibility_lengths
local minimum_distance = dash_config.minimum_distance --after this distance, the dash will stop before you hit water, a hole, etc
local bad_ground_lookahead = dash_config.bad_ground_lookahead --how far ahead of your movement to check for holes, water, etc
local recovery_length = dash_config.recovery_length
local dash_cooldown_time = dash_config.dash_cooldown_time
local can_cross_hole = dash_config.can_cross_hole


local bad_grounds = {
  hole = true,
  deep_water = true,
  lava = true,
  prickles = true,
}


function game_meta:set_dash_level(lvl)
  self:set_value("dash_level", lvl)
end

function game_meta:get_dash_level()
  return self:get_value("dash_level")
end

local dash_state = sol.state.create("dashing")
dash_state:set_can_control_direction(false)
dash_state:set_can_control_movement(false)
dash_state:set_can_traverse_ground("hole", true)
dash_state:set_can_traverse_ground("deep_water", true)
dash_state:set_can_traverse_ground("lava", true)
dash_state:set_affected_by_ground("hole", false)
dash_state:set_affected_by_ground("deep_water", false)
dash_state:set_affected_by_ground("lava", false)
dash_state:set_gravity_enabled(false)
dash_state:set_can_come_from_bad_ground(false)
dash_state:set_can_be_hurt(true) -- this gets over written by the iframe functionality
dash_state:set_can_use_sword(false)
dash_state:set_can_use_item(false)
dash_state:set_can_interact(false)
dash_state:set_can_grab(false)
dash_state:set_can_push(false)
dash_state:set_can_pick_treasure(true)
dash_state:set_can_use_teletransporter(true)
dash_state:set_can_use_switch(true)
dash_state:set_can_use_stream(false)
dash_state:set_can_use_stairs(true)
dash_state:set_can_use_jumper(true)
dash_state:set_carried_object_action("throw")

function hero_meta:get_dash_state()
  return dash_state
end


local function is_bad_ground(ground)
  return bad_grounds[ground]
end

function dash_state:on_started()
  --Allow a short time to readjust dash angle after starting
  local redirect_window_length = 80
  dash_state.redirect_window = true
  sol.timer.start(dash_state, redirect_window_length, function() dash_state.redirect_window = nil end)
  --Set initial position:
  local x, y, z = dash_state:get_entity():get_position()
  dash_state.initial_position_x = x
  dash_state.initial_position_y = y
  dash_state.bad_ground_touched = false
  dash_state.bad_ground_touched_center = false
end

function dash_state:on_finished()
  local hero = dash_state:get_entity()
  if hero.dash_collider then
    hero.dash_collider:remove()
    hero.dash_collider = nil
  end
end

function dash_state:on_position_changed(x, y, z)
  local hero = dash_state:get_entity()
  local map = hero:get_map()
  local m = hero:get_movement()
  if hero.dash_collider then
    hero.dash_collider:set_position(x, y, z)
  end
  local distance_traveled = sol.main.get_distance(dash_state.initial_position_x, dash_state.initial_position_y, x, y)
  local ground = map:get_ground(hero:get_position())

  --If over bad ground:
  if is_bad_ground(ground) then
    dash_state.bad_ground_touched = true
    local center_ground = map:get_ground(hero:get_center_position())
    if is_bad_ground(center_ground) then dash_state.bad_ground_touched_center = true end
    --If you're over a dangerous ground and the dash is not for platforming, stop so you can fall:
    if not dash_state.can_cross_hole then
      m:stop()
      hero:unfreeze()
    end

  --If over safe ground:
  else
    --Stop short if you'd fall into a hole or water (and are over safe ground):
    if (dash_state.bad_ground_touched_center or dash_state.distance_traveled > minimum_distance) and m then
      local angle = (m:get_speed() > 0) and m:get_angle() or (hero:get_direction() * (math.pi / 2))
      local tx, ty = x + math.cos(angle) * bad_ground_lookahead, y + math.sin(angle) * bad_ground_lookahead * -1

      local ground_ahead = map:get_ground(tx, ty, z)
      if is_bad_ground(ground_ahead) then
        m:stop()
      end

    end
  end

end

function dash_state:on_axis_moved(command_axis, state, command_ob)
  --Adjust dash angle after it's started:
  if dash_state.redirect_window then
    local angle = sol.controls.get_main_controls():get_angle()
    local m = dash_state.movement
    if angle and m and m:get_speed() > 0 then
      local current_dir4 = m:get_direction4()
      dash_state.movement:set_angle(angle)
      local new_dir4 = sol.main.get_direction4(angle)
      if new_dir4 ~= current_dir4 then dash_state:get_entity():set_direction(new_dir4) end
    end
  end
end


local dash_recovery_state = sol.state.create("dash_recovery")
dash_recovery_state:set_can_control_direction(true)
dash_recovery_state:set_can_control_movement(true)
dash_recovery_state:set_gravity_enabled(false)
dash_recovery_state:set_can_come_from_bad_ground(true)
dash_recovery_state:set_can_be_hurt(true)
dash_recovery_state:set_can_use_sword(false)
dash_recovery_state:set_can_use_item(false)
dash_recovery_state:set_can_interact(false)
dash_recovery_state:set_can_grab(false)
dash_recovery_state:set_can_push(false)
dash_recovery_state:set_can_traverse_ground("hole", false)
dash_recovery_state:set_can_traverse_ground("deep_water", false)

function dash_recovery_state:on_started()
  local hero = dash_recovery_state:get_entity()
  hero.dash_cooldown = true
  sol.timer.start(hero:get_game(), dash_cooldown_time, function() hero.dash_cooldown = false end)
  hero:set_animation("dash_recovery", function()
    hero:set_animation"stopped"
  end)
  sol.timer.start(dash_recovery_state, recovery_length, function()
    hero:unfreeze()
  end)
end

function hero_meta:stop_dash()
  local hero = self
  local state, state_ob = self:get_state()
  if not state_ob then return end
  if state_ob:get_description() == "dashing" or state_ob:get_description() == "dash_recovery" then
    hero:stop_movement()
    hero:unfreeze()
  end
end

function hero_meta:dash(props)
  local hero = self
  local game = hero:get_game()
  --Check if we have enough stamina to dash:
  --if not game:can_spend_stamina() then return end

  local map = hero:get_map()
  local intended_direction8 = (game:get_commands_direction() or (hero:get_direction() * 2) % 8)
  local intended_angle
  local movement = hero:get_movement()
  --OPTIONAL: if there are dash upgrades, set dash level. These correspond to values in dash_distances and dash_speeds tables
  local dash_level = game:get_value("dash_level") or 1
  props = props or {}
  local iframe_duration = props.iframe_duration or invincibility_lengths[dash_level]
  local dash_speed = props.speed or dash_speeds[dash_level]
  local dash_distance = props.distance or dash_distances[dash_level]
  local dash_animation = props.animation or dash_animations[dash_level]
  local dash_sound = props.sound or dash_sounds[dash_level][math.random(1, #dash_sounds[dash_level])]
  local angle_override = props.angle_override
  local create_dust = props.create_dust or true
  local can_cross_hole = props.can_cross_hole or can_cross_hole[dash_level]

  if hero.dash_cooldown then return end

  --Check movement angle to dash in direction of movement:
  if movement and (movement:get_speed() > 0) then
    intended_angle = movement:get_angle()
  --If joypad connected, but not moving, then check the stick direction. If not pushed, then go by facing direction.
  elseif sol.controls.get_controls_manager().get_active_input_type() == "joypad" then
    local held_angle = sol.controls.get_main_controls():get_angle()
    intended_angle = held_angle or (intended_direction8 * math.pi / 4)
  --If keyboard input being used, dash in facing direction:
  else
    intended_angle = intended_direction8 * math.pi / 4
  end
  if angle_override then intended_angle = angle_override end

  --Start state
  hero:start_state(dash_state)

  --Spend stamina:
  -- game:remove_stamina(dash_stamina_cost)

  --Init values for dash state:
  dash_state.distance_traveled = 0
  dash_state.bad_ground_touched = false
  dash_state.can_cross_hole = can_cross_hole

  --i-frames
  dash_state:set_can_be_hurt(false)
  sol.timer.start(dash_state, iframe_duration, function()
    dash_state:set_can_be_hurt(true)
  end)
  hero:set_invincible(true, iframe_duration)

  --destroy any breakable objects that are close
  local hx, hy, hz = hero:get_position()
  hero.dash_collider = map:create_custom_entity{
    x=hx, y=hy, layer=hz, width=16, height=16, direction=0,
    sprite = "hero/collider_square_small",
  }
  hero.dash_collider:set_visible(false)
  hero.dash_collider:add_collision_test("sprite", function(collider, entity)
    if (entity:get_layer() == hz) and (entity:get_type() == "custom_entity") and (entity:get_model() == "world_objects/breakable_object") then
      if entity.explosion_required then return end
      entity:destroy()
    end
  end)


  local function end_dash()
    hero.dashing = false
    local state, state_ob = hero:get_state()
    if state_ob and state_ob:get_description () == "dashing" then
      local ground = map:get_ground(hero:get_position())
      if ground == "hole" then
        hero:stop_movement()
        hero:unfreeze()
      elseif state_ob and state_ob:get_description() ~= "dash_recovery" then
        --Check to start sprinting after dash:
        if sol.main.get_game():is_command_pressed("dodge") and hero:can_sprint() then
          hero:start_sprinting()
        else
          hero:start_state(dash_recovery_state)
        end
      end
    end
  end

  --create movement
  hero:set_direction(intended_direction8 / 2)
  local m = sol.movement.create("straight")
  m:set_angle(intended_angle)
  m:set_speed(dash_speed)
  m:set_max_distance(dash_distance)
  m:set_smooth(true)
  m:start(hero)
  dash_state.movement = m --save movement so it can be adjusted if needed

  --Rather than ending state on obstacle hit or movement max reached, end the state after X amount of time has passed:
  local dash_duration = (dash_distance / dash_speed) * 1000
  sol.timer.start(dash_state, dash_duration, function()
    --NOTE: if the hero is getting frozen and not coming out of a dash, this callback has likely been prevented somehow.
    end_dash()
  end)

  --Animation/Sound
  local animation = dash_animation
  hero:set_animation(animation, function()
    hero:set_animation("walking")
  end)
  sol.audio.play_sound(dash_sound)


  --create little dust effects
  if create_dust then
    local num_clouds = 4
    local cloud_delay = 40
    for i = 0, num_clouds - 1 do
      sol.timer.start(map, cloud_delay * i, function()
        local hx, hy, hz = hero:get_position()
        direction = hero:get_direction()
        local ground = map:get_ground(hx, hy, hz)
        if ground == "traversable" or ground == "grass" or ground == "ladder" or ground == "shallow_water" then
          local dust_cloud = map:create_custom_entity({
            direction = 0, x = hx, y = hy, layer = hz, width = 16, height = 16,
            sprite = "entities/roll_effect",
            model = "ephemeral_effect"
          })
          local dust_sprite = dust_cloud:get_sprite()
          if ground == "shallow_water" then
            dust_sprite:set_animation("ripple")
          end
          dust_sprite:set_direction(math.random(0, dust_sprite:get_num_directions() - 1))
        end
      end)
    end
    --Burst sprite:
    local hx, hy, hz = hero:get_position()
    local burst = map:create_custom_entity({
      direction = 0, x = hx, y = hy, layer = hz, width = 16, height = 16,
      sprite = "effects/dash_burst",
      model = "ephemeral_effect"
    })
    local burst_sprite = burst:get_sprite()
    burst_sprite:set_xy(0, -8)
    burst_sprite:set_scale(1, 0.6)
    burst_sprite:set_rotation(intended_angle)
    burst_sprite:set_opacity(150)
    burst_sprite:set_color_modulation({216,202,160})
  end

  --Add a trigger for charms that the hero has just started dashing
  game.event_manager:trigger_event("on_dashing")
end


function hero_meta:is_dashing()
  return dash_state:is_started() and dash_state:get_entity() == self
end


