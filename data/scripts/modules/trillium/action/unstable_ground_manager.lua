--[[
Created by Max Mraz, licensed MIT

Automatically sets saved position for hero only if ground is stable.
Custom entities such as collapsing platforms can set a property ("unstable_floor"), which prevents them from being indexed as a safe location
--]]

local manager = {}

local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"
local hero_meta = sol.main.get_metatable"hero"


function map_meta:is_unstable_ground(x, y, z)
  local map = self
  local ground = map:get_ground(x, y, z)
  local is_unstable = false
  if (ground == "hole") or (ground == "lava") or (ground == "deep_water") then
    is_unstable = true
  end
  for e in map:get_entities_in_rectangle(x, y, 1, 1) do
    if e:get_property("unstable_floor") == "true" and e:get_layer() == z then
      is_unstable = true
    end
  end
  --If you're on an empty ground and not the lowest layer, check below you:
  if ground == "empty" and z > map:get_min_layer() then
    is_unstable = map:is_unstable_ground(x, y, z - 1)
  end

  return is_unstable
end


function hero_meta:set_stable_ground_position() --note: only call if you know the player is not over an unstable ground
  local hero = self
  local x, y, z = hero:get_position()
  hero.saved_stable_ground_position = {
    x = x, y = y, layer = z,
  }
end


function hero_meta:get_stable_ground_position()
  local hero = self
  local pos = hero.saved_stable_ground_position or {x = nil, y = nil, layer = nil}
  return pos.x, pos.y, pos.layer
end


hero_meta:register_event("on_position_changed", function(hero)
  --Save stable ground position unless we shouldn't
  local state, state_ob = hero:get_state()
  if state_ob then state = state_ob:get_description() end
  if state == "back to solid ground" or state == "falling" or state == "hookshot" then
    return
  elseif (state_ob and not state_ob:get_can_come_from_bad_ground()) then
    return
  else
    local map = hero:get_map()
    local x, y, z = hero:get_ground_position()
    if not map:is_unstable_ground(x, y, z) then
      hero:set_stable_ground_position()
    end
  end
end)


function hero_meta:activate_bad_ground_recall()
  local hero = self
  --Overwrite the engine's built-in recall behavior for when you fall in a hole or whatever
  --Set a function to be called whenever the hero falls into a bad ground - the function returns where to place the hero on recovering
  hero:save_solid_ground(function()
    return hero:get_stable_ground_position() --give the engine our custom saved position to return the hero to
  end)
end

local old_reset_solid_ground = hero_meta.reset_solid_ground
function hero_meta:reset_solid_ground()
  --Whenever we reset the solid ground, make sure to re-activate bad ground recall
  old_reset_solid_ground(self)
  self:activate_bad_ground_recall()
end


map_meta:register_event("on_opening_transition_finished", function(map)
  local hero = map:get_hero()
  if hero:get_state() == "stairs" then --if you're on stairs, we need to make an exception until you're off
    hero.save_ground_once_stairs_are_finished = true
  else --Otherwise, save our new position and reactive bad ground recall behavior
    hero:set_stable_ground_position()
    hero:activate_bad_ground_recall()
  end
end)


hero_meta:register_event("on_state_changing", function(hero, old_state, new_state)
  --If we entered the map via stairs, NOW we can save the ground position once we're free:
  if old_state == "stairs" and new_state == "free" and hero.save_ground_once_stairs_are_finished then
    hero.save_ground_once_stairs_are_finished = nil
    hero:set_stable_ground_position()
    hero:activate_bad_ground_recall()
  end
end)


--Overwrite "back to solid ground" recovery so immediately move the hero to our special saved location:
hero_meta:register_event("on_state_changed", function(hero, new_state)
  if new_state == "back to solid ground" then
    hero:set_position(hero:get_stable_ground_position())
    --Kick the hero out of recovery state: otherwise the engine will try to move the hero to its recovery location instead of our saved one:
    sol.timer.start(hero, 10, function() hero:unfreeze() end)
  end
end)




return manager
