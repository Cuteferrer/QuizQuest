--[[
Created by Max Mraz, licensed MIT

Functions for climbing, like ladders and climbing walls
--]]

local manager = {}
local SLOWDOWN = 50 --speed slowdown while climbing

--make accessible as module:
sol.modules.register_object("climb_manager", manager)

local state = sol.state.create("climbing")
state:set_visible(true)
state:set_can_control_direction(true)
state:set_can_control_movement(true)
state:set_gravity_enabled(false)
state:set_can_come_from_bad_ground(false)
state:set_can_be_hurt(false)
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
state:set_can_use_stairs(true)
state:set_can_use_jumper(true)
state:set_carried_object_action("throw")

function manager.get_state()
  return state
end

function state:on_started()
  local map = state:get_map()
  local hero = map:get_hero()
  hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED - SLOWDOWN)
  if hero:get_animation() ~= "climbing" then
    hero:set_animation"climbing_stopped"
  end
end


function state:on_position_changed()
  --Check if we're still on a climbing wall
  local map = state:get_map()
  local hero = state:get_entity()
  local on_wall = false
  for e in map:get_entities_in_rectangle(hero:get_bounding_box()) do
    if e:get_type() == "custom_entity" and e:get_model() == "climbing_wall" then
      on_wall = true
      break
    end
  end
  if not on_wall then
    --End state:
    hero:freeze()
    sol.audio.play_sound"hero_lands"
    if hero:get_direction() == 3 then
      hero:unfreeze()
    else
      hero:unfreeze()
    end
  end
end


function state:on_finished()
  local hero = state:get_map():get_hero()
  hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED)
end


function state:on_movement_changed(m)
  local hero = state:get_entity()
  if not hero:get_sprite():has_animation("climbing") then return end
  if m:get_speed() > 0 and hero:get_animation() ~= "climbing" then
    hero:set_animation"climbing"
  elseif m:get_speed() == 0 then
    hero:set_animation"climbing_stopped"
  end
end

return manager