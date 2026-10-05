--[[
Created by Max Mraz, CC0
A platform that will move back and forth over holes and stuff

You can set some properties on the entity:
speed: how fast the platform moves (default 50px/s)
time_paused: how long the platform pauses when it hits an obstacle before going back the other way (default 1000ms)
direction: which direction the platform moves in (as a number bwtween 0-3).
  If not specified, it will use the direction of the entity's sprite.
  If set to "none" it will not automatically move, but can be moved by other scripts.

The moving platform will move any entity types listed in the movable_entity_types table, below.
For custom entities to be moved, they must have the value:
  custom_entity.can_ride_moving_platform = true

--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local movable_entity_types = {
  "hero",
  "pickable",
  "destructible",
  "chest",
  "enemy",
  "npc",
  "crystal",
  "bomb",
  "fire",
  "custom_entity",
}
for _, entity_type in pairs(movable_entity_types) do
  movable_entity_types[entity_type] = true
end

function entity:on_created()
  --Set adjustable properties:
  entity.speed = tonumber(entity:get_property("speed")) or 50
  entity.time_paused = entity:get_property("time_paused") or 1000
  entity.initial_direction = entity:get_property("direction")

  --Set initial_position
  entity.pos_x, entity.pos_y = entity:get_position()

  entity:set_can_traverse(true)
  entity:set_can_traverse("block", false)
  entity:set_can_traverse("wall", false)
  entity:set_can_traverse("enemy", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("traversable", false)
  entity:set_can_traverse_ground("shallow_water", false)
  entity:set_can_traverse_ground("wall", false)
  entity:set_modified_ground("traversable")
  --Set unstable floor property so ground isn't saved:
  entity:set_property("unstable_floor", "true")

  if entity:get_property("direction") ~= "none" then
    local init_angle = (entity.initial_direction or entity:get_direction()) * math.pi / 2
    entity:move(init_angle)
  end
end


function entity:move(angle)
  local m = sol.movement.create"straight"
  m:set_angle(angle)
  m:set_speed(entity.speed)
  m:start(entity)

  entity:add_collision_test("touching", function(entity, other)
    if other:get_type() == "wall" then
      m:stop()
      m:on_obstacle_reached()
    end
  end)

  function m:on_obstacle_reached()
    m.on_obstacle_reached = nil
    entity:stop_movement()
    sol.timer.start(entity, entity.time_paused, function()
      local new_angle = (angle + math.pi) % (2 * math.pi)
      entity:move(new_angle)
    end)
  end
end


function entity:on_movement_changed(m)
  local sprite = entity:get_sprite()
  if sprite:get_num_directions() == 4 then
    sprite:set_direction(m:get_direction4())
  end
end


function entity:on_position_changed()
  local x, y, z = entity:get_center_position()
  local width, height = entity:get_size()
  for passenger in map:get_entities_in_rectangle(x - width/2, y - height/2, width, height) do
    if entity:is_on_platform(passenger) and passenger ~= entity then
      entity:move_passenger(passenger)
    end
  end
  entity.pos_x, entity.pos_y = entity:get_position()
end


function entity:is_on_platform(passenger)
  local passenger_type = passenger:get_type()
  if not movable_entity_types[passenger_type] then return false end
  if passenger_type == "custom_entity" and not passenger.can_ride_moving_platform then return false end
  if passenger_type == "hero" then
    --Hack: if the hero is swimming or plunging, they must not be on the platform. Don't move them.
    local state = passenger:get_state()
    if state == "swimming" or state == "plunging" then
      return false
    end
  end
  local px, py, pz = passenger:get_position()
  local ex, ey, ez = self:get_center_position()
  if ez ~= pz then return false end
  local width, height = entity:get_size()
  --Increase the effective size of the platform just a little bit
  width = width + 4
  height = height + 6
  if math.abs(ex - px) <= width/2 and math.abs(ey - py) <= height/2 then
    return true
  else
    return false
  end
end


function entity:move_passenger(passenger)
  local x, y = entity:get_position()
  local dx = x - entity.pos_x
  local dy = y - entity.pos_y

  local px, py, pz = passenger:get_position()
  if not passenger:test_obstacles(dx, dy, pz) then
    passenger:set_position(px + dx, py + dy, pz)
  end
end

