local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  local sprite = entity:get_sprite()
  entity.initial_state = entity:get_property("initial_state") or "closed"
  entity.closed_threshold = tonumber(entity:get_property("closed_threshold") or 4)
  entity.save_state = entity:get_property("save_state") or false
  entity.max_level = sprite:get_num_frames() - 1
  entity.open_level = (entity.initial_state == "closed") and 0 or entity.max_level

  entity:set_drawn_in_y_order(true)

  function entity:on_pre_draw(camera)
    sprite:set_frame(entity.open_level)
  end

  if entity.initial_state == "closed" then
    entity:set_traversable_by(false)
  end

  if entity.save_state then
    local map_id = map:get_id():gsub("/", "_")
    local x, y, z = entity:get_position()
    entity.savegame_var = "pull_chain_door_level_" .. map_id .. "_" .. x .. "_" .. y .. "_" .. z
    local saved_level = game:get_value(entity.savegame_var) or 0
    entity:set_open_level(saved_level)
  end
end


local function get_push_movement(e)
  local ex, ey, ez = e:get_position()
  local x, y, z = entity:get_center_position()
  local angle = (ey >= y) and (3 * math.pi / 2) or (math.pi / 2)
  local m = sol.movement.create"straight"
  m:set_speed(100)
  m:set_max_distance(24)
  m:set_angle(angle)
  m:set_ignore_obstacles(true)
  return m
end


function entity:get_open_level()
  return entity.open_level
end


function entity:set_open_level(new_level)
  assert(new_level, "Cannot call 'set_open_level' without passing a new level")
  new_level = math.min(new_level, entity.max_level)
  local old_level = entity.open_level
  if new_level > entity.max_level then return end


  if new_level == entity.closed_threshold and new_level < old_level then
    --Become closed:
    entity:set_traversable_by(false)
    entity:set_traversable_by("hero", function(entity, other) return entity:overlaps(other) end)
    entity:set_traversable_by("enemy", function(entity, other) return entity:overlaps(other) end)
    for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
      if e:get_type() == "hero" then
        local m = get_push_movement(e)
        m:start(e, function()
          e:unfreeze()
        end)

      elseif e:get_type() == "enemy" then
        local m = get_push_movement(e)
        m:start(e, function() end)
      end
    end

  elseif new_level > entity.closed_threshold then
    --Become open
    entity:set_traversable_by(true)
    entity:set_traversable_by("hero", true)
    entity:set_traversable_by("enemy", true)
  end

  entity.open_level = new_level

  if entity.save_state then
    game:set_value(entity.savegame_var, new_level)
  end
end



