local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  local target_speed = entity:get_property"target_speed" or 200
  local recenter_speed = entity:get_property"recenter_speed" or 500
  local target_position_x, target_position_y = entity:get_center_position()
  if entity:get_property("target_position_x") then
    target_position_x = entity:get_property"target_position_x"
    target_position_y = entity:get_property"target_position_y"
  end

  entity:set_visible(false)

  entity:add_collision_test("containing", function(entity, other)
    if not entity.containing_hero and (other:get_type() == "hero") then
      local hero = other
      entity.containing_hero = true
      local camera = map:get_camera()
      camera:scroll_to(target_position_x, target_position_y, target_speed)

      sol.timer.start(entity, 100, function()
        if entity.containing_hero and not entity:overlaps(hero, "containing") then
          entity.containing_hero = false
          if game.activate_ease_tracking then
            camera:start_tracking(hero) --easing will smooth this out
          else
            camera:scroll_to_hero(hero, recenter_speed)
          end
        end
        return true
      end)
    end
  end)

end


function entity:safe_remove()
  if entity.containing_hero then
    local camera = map:get_camera()
    local hero = map:get_hero()
    entity.containing_hero = false
    camera:scroll_to(hero, recenter_speed)
    entity:remove()
  end
end



