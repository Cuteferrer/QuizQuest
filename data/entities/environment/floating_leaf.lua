local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  local sprite = entity:get_sprite()
  --Face random direction (each direction is a different leaf pattern)
  sprite:set_direction(math.random(0, sprite:get_num_directions() - 1))
  entity:set_size(8, 8)
  entity:set_origin(4, 5)

  entity:set_can_traverse_ground("traversable", false)
  entity:set_can_traverse_ground("grass", false)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)

  entity.home_x, entity.home_y = entity:get_position()
  entity:start_drifting()
end


function entity:start_drifting(angle)
  local m = sol.movement.create"straight"
  m:set_angle(math.rad(math.random(0,360)))
  if angle then m:set_angle(angle) end
  m:set_speed(5)
  m:set_max_distance(math.random(4, 16))

  local function finish_drift()
    sol.timer.start(entity, math.random(1000, 3000), function()
      local angle
      if entity:get_distance(entity.home_x, entity.home_y) > 40 then angle = entity:get_angle(entity.home_x, entity.home_y) end
      entity:start_drifting(angle)
    end)
  end

  m:start(entity, finish_drift)
  m.on_obstacle_reached = finish_drift
end


function entity:start_drifting()
  entity.drift_dir = (entity.drift_dir or 1) * -1
  local m = sol.movement.create"straight"
  m:set_angle( (math.pi/2 + math.rad(math.random(-15, 15))) + (math.pi/2 * entity.drift_dir) )
  m:set_speed(10)
  m:set_max_distance(math.random(4, 16))

  local function finish_drift()
    sol.timer.start(entity, math.random(200, 2000), function()
      local angle
      if entity:get_distance(entity.home_x, entity.home_y) > 40 then angle = entity:get_angle(entity.home_x, entity.home_y) end
      entity:start_drifting(angle)
    end)
  end

  m:start(entity, finish_drift)
  m.on_obstacle_reached = finish_drift
end
