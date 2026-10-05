local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_visible( entity:get_property("visible") or false)
  entity.cooldown_duration = entity:get_property("cooldown_duration") or 3000

  entity:add_collision_test("containing", function(entity, other)
    if entity.trigger_cooldown then return end
    if other:get_type() == "hero" 
      entity:trigger_crusher()
    end
  end)
end


function entity:trigger_crusher()
  entity.trigger_cooldown = true
  sol.timer.start(entity, entity.cooldown_duration, function()
    entity.trigger_cooldown = false
  end)


end



