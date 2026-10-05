-- Provides additional camera features for this quest.

local camera_meta = sol.main.get_metatable("camera")


function camera_meta:shake(config, callback)
  local game = sol.main.get_game()
  if not game:get_value("option_screenshake_active") then return end --disable screenshake option
	local camera = self
	local camera_surface = camera:get_surface()

	local amplitude = config and config.amplitude or 3
	local speed = config and config.speed or 50
	local zoom_scale = config and config.zoom_scale or 1.05
	local shake_count = config and config.shake_count or 8
	if (shake_count % 2) == 0 then shake_count = shake_count + 1 end

  --Shake
  local i = 1
  camera.shake_timer = sol.timer.start(camera, 0, function()
    if i <= shake_count then
      local dir = (i % 2 == 0) and 1 or -1
      camera:set_position_on_screen(amplitude * dir, 0)
      i = i + 1
      return 1000 / speed
    else
      camera:set_position_on_screen(0,0)
      if callback then callback() end
    end
  end)

  --Zoom
  local j = 1
  camera.shake_zoom_timer = sol.timer.start(camera, 0, function()
    if j <= shake_count then
      if (j % 2 == 0) then
        camera:set_zoom(1,1)
      else
        camera:set_zoom(zoom_scale, zoom_scale)
      end
      j = j + 1
      return 20
    else
      camera:set_zoom(1, 1)
    end
  end)

end


function camera_meta:stop_shaking()
  local camera = self
  if camera.shake_timer then camera.shake_timer:stop() end
  if camera.shake_zoom_timer then camera.shake_zoom_timer:stop() end
end


function camera_meta:scroll_to_hero(hero, speed)
  local camera = self
  local tracking_threshold = 16

  local m = sol.movement.create("target")
  m:set_target(camera:get_position_to_track(hero))
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  m:start(camera, function()
    camera:start_tracking(hero)
  end)
  local x1, y1 = hero:get_position()
  function m:on_position_changed()
    local x2, y2 = hero:get_position()
    if sol.main.get_distance(x1, y1, x2, y2) > tracking_threshold then
      x1, y1 = hero:get_position()
      m:set_target(camera:get_position_to_track(hero))
    end
  end
end


function camera_meta:scroll_to(target_x, target_y, target_speed) --can do either scroll_to(x, y, speed) or scroll_to(entity, speed)
  local camera = self
  target_speed = target_speed or 200
  if type(target_x) ~= "number" then
    assert(type(target_x) == "userdata", "What did you pass as argument #1 to camera:scroll_to()?")
    target_speed = target_y or 200
    if target_x:get_type() == "hero" then
      camera:scroll_to_hero(target_x, target_speed)
    else
      camera:scroll_to_entity(target_x, target_speed)
    end

  else
    local m = sol.movement.create("target")
    m:set_target(camera:get_position_to_track(target_x, target_y))
    m:set_speed(target_speed)
    m:set_ignore_obstacles(true)
    m:start(camera)  
  end
end


function camera_meta:scroll_to_entity(entity, speed)
  local camera = self
  local x, y = entity:get_position()
  camera:scroll_to(x, y, speed)
  local m = entity:get_movement()
  sol.timer.start(camera, 10, function()
    if m and m:get_speed() > 0 then
      camera:get_movement():set_target(camera:get_position_to_track(entity:get_position()))
      return true
    end
  end)
end

