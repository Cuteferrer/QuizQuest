--[[
Created by Max Mraz, licensed MIT

A rotating cylinder that faces one of 4 directions. Interaction rotates it one direction.
Entity properties:
lock_group --when all locks in a lock group are in their correct rotation, map:on_cylinder_lock_unlocked(lock_group) will be called
unlock_direction --set which direction cylinder needs to face to trigger unlock event

Map events to define:
function map:on_cylinder_lock_unlocked(lock_group)
  if lock_group == "whatever" then
    --some effect, open a door or whatever
  end
end

--]]
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()


function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)

  entity.lock_group = entity:get_property("lock_group") or "default"
  entity.unlock_direction = tonumber(entity:get_property("unlock_direction") or 3)
end


function entity:on_interaction()
  local new_dir = (entity:get_direction() + 1) % 4
  entity:set_direction(new_dir)

  sol.timer.start(entity, 500, function()
    entity:check_unlock()
  end)

  local sfx = sol.sound.create("bell")
  sfx:set_pitch(.5)
  sfx:set_volume(70)
  sfx:play()
end


function entity:check_unlock()
  local should_unlock = true
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model() == "puzzle/cylinder_lock" and e.lock_group == entity.lock_group then
      if e:get_direction() ~= e.unlock_direction then
        should_unlock = false
        break
      end
    end
  end
  if should_unlock and map.on_cylinder_lock_unlocked then
    map:on_cylinder_lock_unlocked(entity.lock_group)
    local sfx = sol.sound.create("bell_low")
    sfx:set_pitch(.1)
    sfx:play()
    sol.sound.create("bell_low"):play()
  end
end

