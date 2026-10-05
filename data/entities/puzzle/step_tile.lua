--[[
Created by Max Mraz, licensed MIT

One of those tile puzzles where you have to step on each one exactly once

Setup:
- Give each tile a "group" entity property with an ID for the group
- Create a sensor or something to reset the puzzle at its entrance. Sensor should call map:reset_step_tile_puzzle(group_id)
- NOTE: I set up a check on the sensor metatable so you just need to place a sensor with the property "reset_step_tile" and value of the group id

Map callback on puzzle success:
function map:on_step_tile_success(group)
  if group == "my_group" then

  end
end

Map reset function:
map:reset_step_tile_puzzle(group)

--]]

--Map helper:
local map_meta = sol.main.get_metatable"map"
function map_meta:reset_step_tile_puzzle(group)
  local map = self
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model() == "puzzle/step_tile" and e.group == group then
      e:get_sprite():set_animation("up")
      e.activated = false
      e.locked = false
      e.currently_pressed = false
    end
  end
end



local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()


function entity:on_created()
  entity.group = entity:get_property("group") or "default"
  entity.activated = false
  entity.locked = false
  entity.currently_pressed = false

  entity:add_collision_test("origin", function(entity, other)
    if other:get_type() == "hero" then
      entity:check_collision(other)
    end
  end)
end


function entity:check_collision(hero)
  if entity.locked then return end --ignore collision if locked by success or failure
  if not entity.activated and not entity.currently_pressed then
    --first step onto tile
    entity:activate(hero)
  elseif entity.activated and not entity.currently_pressed then
    --step onto tile again
    entity:fail()
  end
end


function entity:activate(hero)
  sprite:set_animation("down")
  entity.activated = true
  entity.currently_pressed = true
  sol.timer.start(entity, 50, function()
    if entity:overlaps(hero, "origin") then
      return true
    else
      entity.currently_pressed = false
    end
  end)
  entity:check_success()
  local sfx = sol.sound.create("switch_low_short")
  sfx:set_pitch(math.random(95, 105) / 100)
  sfx:play()
end


function entity:check_success()
  local all_activated = true
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model() == "puzzle/step_tile" and e.group == entity.group then
      if not e.activated then
        all_activated = false
        break
      end
    end
  end
  if all_activated then
    --lock in success:
    for e in map:get_entities_by_type("custom_entity") do
      if e:get_model() == "puzzle/step_tile" and e.group == entity.group then
        e:lock_success()
      end
    end
    --call map callback
    if map.on_step_tile_success then
      map:on_step_tile_success(entity.group)
    end
  end
end


function entity:lock_success()
  entity.locked = true
end


function entity:fail()
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model() == "puzzle/step_tile" and e.group == entity.group then
      e:get_sprite():set_animation("down")
      sol.sound.create("wrong"):play()
      e.locked = true
    end
  end
end

