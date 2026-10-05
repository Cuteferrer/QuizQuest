sol.modules.get_object("multi_events")

local map_meta = sol.main.get_metatable"map"


function map_meta:is_opening_transition()
  return self.started_but_not_opening_transition_finished
end

map_meta:register_event("on_started", function(map)
  map.started_but_not_opening_transition_finished = true
end)

map_meta:register_event("on_opening_transition_finished", function(map)
  map.started_but_not_opening_transition_finished = false
end)


local function calculate_speed(entity1, entity2, duration)
  duration = duration / 1000
  local x1, y1 = entity1:get_position()
  local x2, y2 = entity2:get_position()
  local distance = math.abs(sol.main.get_distance(x1, y1, x2, y2))
  return (distance / duration)
end


--Screenshake
function map_meta:screenshake(config, callback)
  self:get_camera():shake(config, callback)
end


-----Map Focus-----
--[[
map:focus_on(target) event pauses the map, moves the camera to center on an entity, then moves back to the hero
map:start_camera_tracking(target) leaves the map running, and moves the camera to center on an entity. Explicitly call map:stop_camera_tracking() when finished to return focus to the hero

NOTE!!: damnit, I think map:start_camera_tracking(target) is the same as the custom function camera:scroll_to_entity(entity) ..... ope
--]]
function map_meta:focus_on(target_entity, callback, return_delay)
  assert(target_entity, "target_entity is invalid for map_meta:focus_on")
  local game = sol.main.get_game()
  local hero = game:get_hero()
  local camera = self:get_camera()
  hero:freeze()
  game:set_suspended(true)
  local m = sol.movement.create("target")
  m:set_target(camera:get_position_to_track(target_entity))
  local speed = calculate_speed(camera, target_entity, 2000)
  if speed < 140 then speed = 140 end
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  m:start(camera, function()
    if callback then callback() end
    sol.timer.start(game, return_delay or 500, function()
      m2 = sol.movement.create("target")
      m2:set_ignore_obstacles(true)
      m2:set_target(camera:get_position_to_track(hero))
      m2:set_speed(speed + 40)
      m2:start(camera, function()
        camera:start_tracking(hero)
        game:set_suspended(false)
        hero:unfreeze()
      end)
      function m2:on_obstacle_reached() hero:unfreeze() end
    end)
  end)
end


function map_meta:start_camera_tracking(target_entity, callback)
  local camera = self:get_camera()
  local m = sol.movement.create"target"
  m:set_target(camera:get_position_to_track(target_entity))
  local speed = calculate_speed(camera, target_entity, 2000)
  if speed < 140 then speed = 140 end
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  local function finish_moving()
    camera:start_tracking(target_entity)
  end
  m:start(camera, function()
    finish_moving()
    if callback then callback() end
  end)
  --Set a timer so the camera will check periodically if it's "close enough" and snap to the target entity (useful if the target is moving)
  local snap_threshold = 2
  sol.timer.start(self, 50, function()
    local cx, cy = camera:get_position()
    local tx, ty = camera:get_position_to_track(target_entity)
    if (math.abs(cx - tx) <= snap_threshold) and (math.abs(cy - ty) <= snap_threshold) then
      finish_moving()
      return false
    end
    return true
  end)
end


function map_meta:stop_camera_tracking()
  self:start_camera_tracking(self:get_hero())
end


-----Make a poof--------
function map_meta:create_poof(x, y, layer, sprite_id)
  local map = self
  if not sprite_id then sprite_id = "entities/poof" end
  local poof = map:create_custom_entity({
    x = x, y = y+3, layer = layer, direction = 0, height = 16, width = 16,
    sprite = sprite_id,
  })
  poof:set_drawn_in_y_order(true)
  local sprite = poof:get_sprite()
  sol.timer.start(poof, sprite:get_num_frames() * sprite:get_frame_delay(), function() poof:remove() end)
end


--Create explosion, overwrite default engine explosion
function map_meta:create_explosion(props)
  assert(props.x and props.y and props.layer, "map:create_explosion() takes a table that must contain x, y, and layer properties")
  local explosion = self:create_custom_entity{
    x = props.x, y = props.y, layer = props.layer,
    width = 16, height = 16, direction = 0,
    model = "attacks/explosion",
    sprite = props.sprite or "entities/explosion",
  }
  sol.audio.play_sound(props.sound or "explosion")
  return explosion
end




return true
