--[[
Created by Max Mraz, licensed MIT
Creates a few entities to allow a smooth transition from a lower layer to a higher layer and back
Place it on the lower layer so its "going up" edge meets the higher layer
If your stairs are only 2 tiles long (going up to a new layer), maybe extend this entity out an extra tile below the stairs
Otherwise, you could have the ground of the upper layer overlapping your guy
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  entity:set_visible(false)

  local hero = map:get_hero()
  local corner_x, corner_y, width, height = entity:get_bounding_box()
  local x, y, layer = entity:get_position()
  local direction = entity:get_direction()
  local orientation = (direction % 2 == 0) and "horizontal" or "vertical"
  local num_tiles = (orientation == "vertical") and (height / 16) or (width / 16)
  local assumed_ground_type = entity:get_ground_below()
  --print("xywh:", x, y, width, height, orientation, "tiles:", num_tiles)

  --create platform above entity
  local invisible_platform = map:create_custom_entity{
    x=x, y=y, layer=layer+1, width=width, height=height, direction=direction,
  }
  invisible_platform:set_modified_ground(assumed_ground_type or "traversable")

  --create sensors on entity and invisible platform
  local up_x, up_y, down_x, down_y, sensor_width, sensor_height
  --Note: a sensor's position is based on the top-left corner, as (corner + 8, corner + 13)
  --Up
  if direction == 1 then
    up_x = x
    up_y = y + (num_tiles - 2) * 16
    down_x = x
    down_y = y + (num_tiles - 1) * 16
    sensor_width = width
    sensor_height = 16
  --Down
  elseif direction == 3 then
    up_x = x
    up_y = y + (num_tiles - 1) * 16
    down_x = x
    down_y = y + (num_tiles - 2) * 16
    sensor_width = width
    sensor_height = 16
  --Right
  elseif direction == 0 then
    up_x = x + 16
    up_y = y
    down_x = x
    down_y = y
    sensor_width = 16
    sensor_height = height
  --Left
  elseif direction == 2 then
    up_x = x + (num_tiles - 2) * 16
    up_y = y
    down_x = x + (num_tiles - 1) * 16
    down_y = y
    sensor_width = 16
    sensor_height = height
  end

  local go_up_sensor = map:create_sensor{
    x = up_x, y = up_y, layer=layer, width = sensor_width, height= sensor_height
  }
  local go_down_sensor = map:create_sensor{
    x = down_x, y = down_y, layer=layer + 1, width = sensor_width, height = sensor_height
  }

  local go_up_ce_sensor = map:create_custom_entity{
    x = up_x, y = up_y, layer=layer, width = sensor_width, height= sensor_height, direction=0,
  }
  local go_down_ce_sensor = map:create_custom_entity{
    x = down_x, y = down_y, layer=layer + 1, width = sensor_width, height = sensor_height, direction=0,
  }

  --make sensors move the hero
  function go_up_sensor:on_activated(hero)
    hero:set_layer(hero:get_layer() + 1)
  end
  function go_down_sensor:on_activated(hero)
    hero:set_layer(hero:get_layer() - 1)
  end

  ce_sensor_types = { --these types will also get moved up/down along ramps
    --["enemy"]=true, --weird, because their AI won't recognize if the hero is above/below a layer, so they don't have motivation to move up/down the ramp. It ends up weirder if they can go up but then won't come back down.
    ["pickable"]=true,
  }
  go_up_ce_sensor:add_collision_test("containing", function(_, other)
    if ce_sensor_types[other:get_type()] then
      other:set_layer(other:get_layer() + 1)
    end
  end)
  go_down_ce_sensor:add_collision_test("containing", function(_, other)
    if ce_sensor_types[other:get_type()] then
      other:set_layer(other:get_layer() - 1)
    end
  end)

  --create walls
  --NOTE: a wall's position is based on it's top-left corner
  if orientation == "vertical" then
    map:create_wall{
      x = corner_x - 8, y = corner_y, layer = layer + 1,
      width = 8, height = height,
      stops_hero = true,
    }
    map:create_wall{
      x = corner_x + width, y = corner_y, layer = layer + 1,
      width = 8, height = height,
      stops_hero = true,
    }
  elseif orientation == "horizontal" then
    map:create_wall{
      x = corner_x, y = corner_y - 8, layer = layer + 1,
      width = width, height = 8,
      stops_hero = true,
    }
    map:create_wall{
      x = corner_x, y = corner_y + height, layer = layer + 1,
      width = width, height = 8,
      stops_hero = true,
    }
  end
end
