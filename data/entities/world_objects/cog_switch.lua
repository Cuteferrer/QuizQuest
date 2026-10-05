--[[
By Max Mraz, licensed MIT
A switch that can only be activated with the Drillspear item
Use as a custom entity, and write map code like any other switch (i.e., define on_activated, on_inactivated)
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  local initial_state = entity:get_property"initial_state"
  if initial_state then
    if (initial_state == "activated") or (initial_state == "active") then
      entity.activated = true
    else
      entity.activated = false
    end
  end
end

function entity:is_activated()
  return entity.activated
end

function entity:set_activated(should_activate)
  if should_activate then
    entity:activate()
  else
    entity:inactivate()
  end
end

function entity:react_to_drillspear()
  local hero = game:get_hero()
  local x, y, z = entity:get_position()
  local hx, hy, hz = hero:get_position()
  hero:set_position(x, y + 24, hz)
  hero.drillspear:set_position(x, y + 32, z)
  if not entity.activated then
    entity:activate()
  else
    entity:inactivate()
  end
end


function entity:activate()
  entity.activated = true
  sol.audio.play_sound"switch"
  entity:get_sprite():set_animation("activated")
  if entity.on_activated then entity:on_activated() end
end


function entity:inactivate()
  entity.activated = false
  sol.audio.play_sound"switch"
  entity:get_sprite():set_animation("inactivated")
  if entity.on_inactivated then entity:on_inactivated() end
end
