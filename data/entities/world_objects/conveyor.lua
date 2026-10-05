local entity = ...
local game = entity:get_game()
local map = entity:get_map()

--Entities that can be moved by the conveyor:
local movable_types = {
  hero = true,
  enemy = true,
  pickable = true,
  npc = true,
  block = false, --this was pushing my hookshot posts off the edge of conveyor challenges!
  bomb = true,
}

function entity:on_created()
  entity:set_modified_ground("traversable")
  entity:set_property("unstable_floor", "true")

  --Set conveying speed:
  entity.frequency = tonumber(entity:get_property("frequency") or 30)

  --Set active:
  entity:set_active(tobool(entity:get_property("active") or true))
end


--Heroes may or may not be conveyable depending on their state
local function check_if_hero_can_be_conveyed(hero)
  local can_move = true
  local state, state_ob = hero:get_state()
  local still_states = {
    ["back to solid ground"] = true,
    ["falling"] = true,
    ["jumping"] = true,
    ["lifting"] = true,
    ["grabbing"] = true,
    ["pulling"] = true,
    ["stairs"] = true,
    ["treasure"] = true,
  }
  if still_states[state] then
    can_move = false
  end
  --The states thing absolutely doesn't work in some cases. Wtf.
  --dumb hacky check:
  local anim = hero:get_sprite():get_animation()
  if anim == "falling" then can_move = false end
  return can_move
end


function entity:can_convey(other)
  if not entity.active then return end
  if not entity:overlaps(other) then return end
  local can_move = false
  local other_type = other:get_type()
  if other_type == "hero" then
    can_move = check_if_hero_can_be_conveyed(other)
  elseif movable_types[other_type] then
    can_move = true
  --Custom entities are tricky, who knows if they can be conveyed. Let each set custom_entity.can_be_conveyed if they want to be movable by conveyors
  elseif other_type == "custom_entity" then
    if other.can_be_conveyed then
      can_move = true
    end
  end
  --Stop flying enemies from being moved by conveyors:
  if other_type == "enemy" and other:get_obstacle_behavior() == "flying" then can_move = false end
  return can_move
end


function entity:start_conveying()
  entity.convey_timer = sol.timer.start(entity, entity.frequency, function()
    for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
      if entity:overlaps(e, "origin") and entity:can_convey(e) then
        entity:convey(e)
      end 
   end
    return true
  end)
  entity:get_sprite():set_animation("active")
end


function entity:stop_conveying()
  if entity.convey_timer then entity.convey_timer:stop() end
  entity:get_sprite():set_animation("inactive")
end


function entity:convey(other)
  local x, y, z = other:get_position()
  local angle = entity:get_direction() * math.pi / 2
  local dx, dy = math.cos(angle), math.sin(angle) * -1
  local is_obstacle = other:test_obstacles(dx, dy)
  if not is_obstacle then
    other:set_position(x + dx, y + dy, z)
  end

end


function entity:set_active(active_bool)
  entity.active = active_bool
  if active_bool then
    entity:start_conveying()
  else
    entity:stop_conveying()
  end
end

