local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite
local CONDUCTIVE_DISTANCE = 26


function entity:on_created()
  sprite = entity:get_sprite()
  entity:set_size(16, 16)
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  entity:set_traversable_by("custom_entity", function(entity, other)
    local can_pass = false
    if other:get_type() == "custom_entity" then
      if other:get_model() == "elements/twister" then
        can_pass = true
      end
    end
    return can_pass
  end)
end

function entity:turn_on()
  sprite:set_animation"activated"
  sol.audio.play_sound"switch"
  if entity.on_activated then entity:on_activated() end
  entity.turned_on = true  
end


function entity:turn_off()
  sprite:set_animation"inactivated"
  if entity.on_inactivated then entity:on_inactivated() end
  entity.turned_on = false
end


function entity:react_to_wind()
  sol.timer.stop_all(entity)
  if not entity.turned_on then
    entity:turn_on()
  end
  local turning_duration = entity:get_property"duration" or 5000
  entity.turning_timer = sol.timer.start(entity, turning_duration, function()
    entity:turn_off()
  end)
end
