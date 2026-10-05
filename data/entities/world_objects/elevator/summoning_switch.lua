--[[
Created by Max Mraz, licensed MIT
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  sprite = entity:get_sprite()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
end


function entity:on_interaction()
  local level = tonumber(entity:get_property"level")
  local elevator_id = entity:get_property"elevator_id"
  local elevator
  for e in map:get_entities_by_type"custom_entity" do
    if e:get_model() == "world_objects/elevator/elevator" and e:get_property"elevator_id" == elevator_id then
      elevator = e
    end
  end
  if elevator.moving then
    sol.audio.play_sound("wrong")
    game:start_dialog("world_objects.elevators.in_motion")
  elseif not (elevator.current_level == level) then
    elevator:go_to_level(level)
    sol.audio.play_sound"switch"
    sprite:set_animation("throwing", "activated")
    sol.timer.start(entity, 200, function()
      if not elevator.moving then
        sprite:set_animation"stopped"
      else
        return true
      end
    end)
  else
    sol.audio.play_sound("wrong")
    game:start_dialog("world_objects.elevators.already_on_this_level")
  end
end
