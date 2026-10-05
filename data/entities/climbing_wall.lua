local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local climbing_state = sol.modules.get_object("climb_manager").get_state()

function entity:on_created()
  entity:set_visible(false)
  entity:set_modified_ground("traversable")
  entity:set_traversable_by(false)
  entity:check_climbable()
  local hero = map:get_hero()
  entity:add_collision_test("center", function(entity, other)
    if other:get_type() == "hero" and (not climbing_state:is_started()) and other:get_life() > 0  then
      local s, ob = hero:get_state()
      if ob and ob:get_description() == "climbing" then return end --double check to not start this state twice
      hero:start_state(climbing_state)
    end
  end)
end


function entity:check_climbable()
  local requirement = entity:get_property("requirement_value")
  if requirement and not game:get_value(requirement) then
    entity:set_traversable_by("hero", false)
  else
    entity:set_traversable_by("hero", true)
  end
end


--[[
function entity:on_created()
  entity:set_visible(false)
  local hero = map:get_hero()
  if not map.climbing_walls then map.climbing_walls = {} end

  for e in map:get_entities() do
    if e:get_type() == "custom_entity" and e:get_model() == "climbing_wall" then
      map.climbing_walls[e] = true
    end
  end

  hero:register_event("on_position_changed", function()
    local overlaps = false
    for wall, _ in pairs(map.climbing_walls) do
      if hero:overlaps(wall) then overlaps = true end
    end
    if overlaps and not state:is_started() then
      hero:start_state(state)
    elseif not overlaps and state:is_started() then
      hero:unfreeze()
    end
  end)

  hero:register_event("on_movement_changed", function(hero, movement)
    if hero:get_state_object() and hero:get_state_object():get_description() == "climbing" then
      if movement:get_speed() > 0 then
        hero:set_animation"climbing"
      else
        hero:set_animation"climbing_stopped"
      end
    end
  end)
end
--]]
