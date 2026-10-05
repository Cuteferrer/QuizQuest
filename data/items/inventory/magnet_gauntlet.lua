local item = ...
local game = item:get_game()

local mag_range = 150
local mag_ball_speed = 300
local max_magnet_distance = 170
local mag_movement_speed = 70
local enemy_stun_duration = 2000

function item:on_started()
  item:set_savegame_variable("possession_magnet_gauntlet")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  local ball = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0, sprite = "elements/magnet_energy"
  }
  item.mag_ball = ball
  local ball_sprite = ball:get_sprite()
  ball_sprite:set_animation"ball"
  hero:set_animation"hand_out"
  local m = sol.movement.create"straight"
  m:set_angle(direction * math.pi / 2)
  m:set_speed(mag_ball_speed)
  m:set_max_distance(mag_range)
  m:set_ignore_obstacles(true)
  m:start(ball, function()
    ball:remove()
    item:set_finished()
  end)

  ball:add_collision_test("sprite", function(ball, other_entity)
    if other_entity.is_magnetic or other_entity.can_conduct_electricity
    or other_entity:get_property"is_magnetic" or other_entity:get_property"can_conduct_electricity"
    and not hero:overlaps(other_entity) then
      ball:remove()
      item:pair_with_entity(other_entity)
    elseif other_entity.react_to_magnet_gauntlet then
      other_entity:react_to_magnet_gauntlet()
    elseif other_entity:get_type() == "enemy" then
      other_entity:immobilize(enemy_stun_duration)
    end
  end)
end

function item:pair_with_entity(entity)
  local hero = game:get_hero()
  local map = game:get_map()
  local x, y, z = hero:get_position()
  local ex, ey, ez = entity:get_center_position()
  --unpair if you're standing on the entity
  if hero:overlaps(entity) then
    sol.audio.play_sound"wrong"
    return
    item:set_finished()
  end
  local ray_sprite = hero:create_sprite("elements/magnet_energy")
  hero:bring_sprite_to_back(ray_sprite)
  ray_sprite:set_animation"ray"
  ray_sprite:set_xy(0, -8)
  ray_sprite:set_transformation_origin(0,0)
  ray_sprite:set_scale(hero:get_distance(ex, ey), 4)
  ray_sprite:set_rotation(hero:get_angle(ex, ey))
  local attachment_fizzle = hero:create_sprite("elements/magnet_energy")
  attachment_fizzle:set_animation"fizzle"

  local state = item:get_magnet_state()
  function state:on_pre_draw()
    ex, ey, ez = entity:get_center_position()
    local distance = hero:get_distance(ex, ey)
    local angle = hero:get_angle(ex, ey)
    ray_sprite:set_scale(distance, 4)
    ray_sprite:set_rotation(angle)
    attachment_fizzle:set_xy(distance * math.cos(angle), distance * math.sin(angle) * -1 -8)
  end

  function state:on_finished()
    hero:remove_sprite(ray_sprite)
    hero:remove_sprite(attachment_fizzle)
  end

  function state:on_command_pressed(cmd)
    if cmd == "item_1" or cmd == "item_2" or cmd == "attack" or cmd == "action" then
      sol.timer.start(hero, 10, function()
        hero:unfreeze()
      end)
    elseif cmd == "right" then
      local m = sol.movement.create"straight"
      m:set_angle(0)
      m:set_speed(mag_movement_speed)
      m:start(entity)
    elseif cmd == "up" then
      local m = sol.movement.create"straight"
      m:set_angle(math.pi / 2)
      m:set_speed(mag_movement_speed)
      m:start(entity)
    elseif cmd == "left" then
      local m = sol.movement.create"straight"
      m:set_angle(math.pi)
      m:set_speed(mag_movement_speed)
      m:start(entity)
    elseif cmd == "down" then
      local m = sol.movement.create"straight"
      m:set_angle(3 * math.pi / 2)
      m:set_speed(mag_movement_speed)
      m:start(entity)
    end
  end

  function state:on_command_released(cmd)
    if cmd == "right" or cmd == "up" or cmd == "left" or cmd == "down"
    and not game:is_command_pressed"right" and not game:is_command_pressed"up"
    and not game:is_command_pressed"left" and not game:is_command_pressed"down" then
      entity:stop_movement()
    end
  end

  entity:register_event("on_position_changed", function(self)
    if hero:get_state() == "custom" and hero:get_state_object():get_description() == "magnet_gauntlet" then
      hero:set_direction(hero:get_direction4_to(entity))
      if entity:get_distance(hero) > max_magnet_distance then
        entity:stop_movement()
        hero:unfreeze()
      end
    end
  end)

  hero:start_state(state)
  hero:set_animation"hand_out"
end


function item:get_magnet_state()
  local state = sol.state.create()
  state:set_description"magnet_gauntlet"
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_use_sword(false)
  state:set_can_use_shield(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(true)
  state:set_can_use_switch(true)
  state:set_can_use_stream(true)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")

  return state
end
