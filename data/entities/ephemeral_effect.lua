local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local duration

-- Event called when the custom entity is initialized.
function entity:on_created()
  duration = 1100 --default duration
  entity:set_can_traverse(true)
  entity:set_can_traverse_ground("wall", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_drawn_in_y_order(true)

  local sprite = entity:get_sprite()
  function sprite:on_animation_finished()
    entity:remove()
  end
end

function entity:set_duration(length)
  duration = length
end

function entity:start()
  sol.timer.start(entity, duration, function() entity:remove() end)
end

function entity:remove_on_animation_finished()
  local sprite = entity:get_sprite()
  function sprite:on_animation_finished()
    entity:remove()
  end
end
