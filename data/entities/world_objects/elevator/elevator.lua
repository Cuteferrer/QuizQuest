--[[
Created by Max Mraz, licensed MIT

Entity properties:
elevator_id (required)
speed
switch_sprite
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  local elevator_id = entity:get_property"elevator_id"
  entity:set_traversable_by(true)
  entity:set_modified_ground("traversable") ---THEN WHY DO WE GET STUCK ON WALLS???

  local sprite = entity:get_sprite()
  local width, height = sprite:get_size()
  entity:set_size(width, height)
  entity:set_origin(width / 2, height - 3)

  --Set level, if saved
  local map_id = map:get_id():gsub("/", "_")
  local level_save_id = map_id .. "_elevator_" .. elevator_id .. "_current_level"
  entity.level_save_id = level_save_id
  if game:get_value(level_save_id) then
    entity.current_level = game:get_value(level_save_id)
  end

  entity.linked_entities = {}

  --Find platforms
  entity.platforms = {}
  local x, y, z = entity:get_position()
  for platform in map:get_entities_by_type("custom_entity") do
    if platform:get_type() == "custom_entity" and platform:get_model() == "world_objects/elevator/landing_platform" and platform:get_property("elevator_id") == elevator_id then
      assert(platform:get_property"level", "Elevator landing platforms require a 'level' property (doesn't need to correspond with the map layer)")
      local level = tonumber(platform:get_property"level")
      entity.platforms[level] = platform
      local px, py, pz = platform:get_position()
      --If we've not saved the elevator's level before, then set its level to the closest landing platform
      if not entity.current_level and (px == x) and (py == y) and (pz == z) then
        entity.current_level = level
        game:set_value(level_save_id, level)
      end
    end
  end

  --Find linked tiles
  for e in map:get_entities() do
    if e:get_property"linked_elevator_id" == elevator_id then
      entity:link_entity(e)
    end
  end

  --Create control switch
  local x, y, z = entity:get_center_position()
  local controls = map:create_switch{
    x = x - 8, y = y - 8, layer = z,
    subtype = "walkable", needs_block = false, inactivate_when_leaving = true,
    sprite = entity:get_property"switch_sprite" or "world_objects/elevator/switch_wood",
  }
  entity:link_entity(controls)
  function controls:on_activated()
    if entity.moving then return end
    sol.sound.create("switch"):play()
    entity:choose_direction()
  end

  --Move elevator to current level
  local x, y, z = entity:get_position()
  local tx, ty, tz = entity.platforms[entity.current_level]:get_position()
  entity:set_position(tx, ty, tz)
  for e in pairs(entity.linked_entities) do
    local ex, ey, ez = e:get_position()
    local dx, dy, dz = ex - x, ey - y, ez - z
    e:set_position(tx + dx, ty + dy, tz + dz)
  end

end



function entity:choose_direction()
  local current_level = entity.current_level
  local can_up, can_down = false, false
  if entity.platforms[current_level + 1] then can_up = true end
  if entity.platforms[current_level -1] then can_down = true end

  if can_up and can_down then
    game:start_dialog("world_objects.elevators.direction_question", function(answer)
      if answer == 1 then
        entity:go_to_level(current_level + 1)
      elseif answer == 2 then
        entity:go_to_level(current_level - 1)
      end
    end)
  elseif can_up then
    entity:go_to_level(current_level + 1)
  elseif can_down then
    entity:go_to_level(current_level - 1)
  end
end


function entity:go_to_level(target_level)
  local target_platform = entity.platforms[target_level]
  --Double check that target exists:
  if not target_platform then
    print("warning: no target platform at level:", target_level)
    return
  end
  local x, y, z = target_platform:get_position()
  entity.current_level = target_level
  game:set_value(entity.level_save_id, target_level)

  --Open gates
  for level, platform in pairs(entity.platforms) do
    platform:open()
  end

  --Start movement
  entity.moving = true
  --Slight delay for landing platform gates to open
  local m = sol.movement.create"straight"
  sol.timer.start(entity, 300, function()
    m:set_angle(entity:get_angle(target_platform))
    m:set_ignore_obstacles(true)
    m:set_max_distance(entity:get_distance(target_platform))
    m:set_speed(entity:get_property"speed" or 80)
    m:start(entity)
  end)

  --Sound
  local track_sfx = sol.sound.create("mechanical_track_long")
  track_sfx:play()
  entity.sfx_timer = sol.timer.start(entity, 5000, function()
    if entity.moving then
      track_sfx:play()
    end
  end)


  --Create walls to keep you from falling off
  entity:create_walls()

  --Link hero
  local hero = map:get_hero()
  entity.linked_entities[hero] = hero
  --Check to unlink in case they somehow got off
  sol.timer.start(entity, 10, function()
    if not entity:overlaps(hero) then
      entity.linked_entities[hero] = nil
    else
      --hero:freeze()
      entity.linked_entities[hero] = hero
    end
    return entity.moving
  end)

  local ex, ey, ez = entity:get_position()
  function m:on_position_changed()
    local nx, ny, nz = entity:get_position()
    local dx, dy = nx - ex, ny - ey
    for _, rider in pairs(entity.linked_entities) do
      --don't move hero if they've somehow gotten off
      if rider:get_type() == "hero" and not entity:overlaps(rider) then
      else
        local hx, hy, hz = rider:get_position()
        rider:set_position(hx + dx, hy + dy, ez)
      end
    end

    ex, ey, ez = nx, ny, nz
  end

  function m:on_finished()
    track_sfx:stop()
    entity.sfx_timer:stop()
    entity:set_layer(z)
    entity:bring_to_front()
    for _, rider in pairs(entity.linked_entities) do
      rider:set_layer(z)
      rider:bring_to_front()
    end
    entity:set_modified_ground"traversable" --idk why we'd need this again
    --Close gates
    for level, platform in pairs(entity.platforms) do
      platform:close()
    end
    entity:remove_walls()
    entity.moving = false
    entity:unlink_entity(hero)
    --hero:unfreeze()
  end  
end


function entity:create_walls()
  local width, height = entity:get_size()
  local x, y, width, height = entity:get_bounding_box()
  local z = entity:get_layer()
  local walls = {}
  local function do_wall(x, y, width, height)
    walls[#walls + 1] = map:create_wall{
      x = x, y = y, layer = z, width = width, height = height,
      stops_hero = true,
    }
  end
  do_wall(x, y - 8, width, 8) --top
  do_wall(x - 8, y, 8, height) --left
  do_wall(x + width, y, 8, height) --right
  do_wall(x, y + height, width, 8) --bottom
  for _, wall in pairs(walls) do
    entity:link_entity(wall)
  end
  entity.walls = walls
end

function entity:remove_walls()
  for _, wall in pairs(entity.walls) do
    entity:unlink_entity(wall)
    wall:remove()
  end
end


function entity:link_entity(other)
  entity.linked_entities[other] = other
end


function entity:unlink_entity(other)
  entity.linked_entities[other] = nil
end

