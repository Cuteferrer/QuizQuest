--[[
Created by Max Mraz, licensed MIT

Basically a floor switch, but you don't need to be perfectly aligned
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local triggering_entity_types = {
  hero = true,
  enemy = false,
}

function entity:on_created()

  entity.triggered = false
  triggering_entity_types.enemy = entity:get_property("triggered_by_enemies") or false

  entity:add_collision_test("overlapping", function(entity, other)
    if entity.triggered then return end
    local dist = math.abs(entity:get_center_position() - other:get_position())
    if triggering_entity_types[other:get_type()] and dist < 11 then
      entity:activate()
    end
  end)

end


function entity:activate()
  entity.triggered = true
  local sprite = entity:get_sprite()
  sprite:set_animation("activated")
  entity:make_sound("switch")

  --General activation event
  if entity.on_activated then
    entity:on_activated()
  end

  --Dart shooter trap
  local dart_shooter_prefix = entity:get_property("dart_shooter_prefix")
  if dart_shooter_prefix then
    sol.audio.play_sound"switch"
    for shooter in map:get_entities(dart_shooter_prefix) do
      shooter:shoot()
    end
    sol.timer.start(entity, 6000, function()
      entity.triggered = nil
      sprite:set_animation("inactivated")
    end)
  end

end

