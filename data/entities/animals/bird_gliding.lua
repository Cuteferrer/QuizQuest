--[[
Created by Max Mraz, licensed MIT
A script for a bird that starts off the side of the map, glides across it, then will glide back later
Birds should have animations "gliding" (repeating) and "flapping" (non-repeating)
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  --Entity properties:
  local speed = entity:get_property("speed") or 150
  local off_map_delay_min = entity:get_property("off_map_delay_min") or 5000
  local off_map_delay_max = entity:get_property("off_map_delay_min") or 50000
  local position_variance = entity:get_property("position_variance") or 80
  local angle_variance = entity:get_property("angle_variance") or 15
  ---
  local sprite = entity:get_sprite()
  local direction = entity:get_direction()
  local width, height = entity:get_size()
  local map_width, map_height = map:get_size()
  local x, y, z = entity:get_position()
  local map_overrun
  --Figure out how far off the edge of the map we are, so we can overshot the map by that much on the other side as well:
  if direction % 2 == 0 then
    map_overrun = (x < 0) and (x * -1) or (x - map_width)
  else
    map_overrun = (y < 0) and (x * -1) or (y - map_height)
  end

  local max_distance = ((direction % 2 == 0) and map_width or map_height) + (map_overrun * 2)

  local function fly()
    local angle = entity:get_direction() * math.pi / 2
    angle = angle + math.rad(math.random(angle_variance * -1, angle_variance))
    local m = sol.movement.create("straight")
    m:set_angle(angle)
    m:set_speed(speed)
    m:set_ignore_obstacles(true)
    m:set_max_distance(max_distance)
    m:start(entity, function()
      --Change position a little
      local x, y, z = entity:get_position()
      local offset = math.random(position_variance * -1, position_variance)
      if direction % 2 == 0 then
        entity:set_position(x, y + offset, z)
      else
        entity:set_position(x + offset, y, z)
      end

      entity:set_direction(direction)
      sol.timer.start(entity, math.random(off_map_delay_min, off_map_delay_max), function()
        fly()
      end)
    end)
    sprite:set_direction(m:get_direction4())

    --Flapping animation
    if sprite:has_animation("flapping") then
      sol.timer.start(entity, math.random(1000, 4000), function()
        sprite:set_animation("flapping", function()
          sprite:set_animation("gliding")
        end)
      end)
    end
  end

  sprite:set_animation("gliding")
  sol.timer.start(entity, math.random(off_map_delay_min, off_map_delay_max), function()
    fly()
  end)  

end
