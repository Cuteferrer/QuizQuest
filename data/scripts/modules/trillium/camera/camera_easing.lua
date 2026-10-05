local camera_meta = sol.main.get_metatable"camera"
local hero_meta = sol.main.get_metatable"hero"
local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"
local destination_meta = sol.main.get_metatable"destination"
local tele_meta = sol.main.get_metatable"teletransporter"
local separator_meta = sol.main.get_metatable"separator"



-----------------------------------------------------------------------------------------------------------------------
--Set up ease tracking to activate when needed, set hacks for anything that doesn't work with it:
-----------------------------------------------------------------------------------------------------------------------
  --Note: Easing formula is basically:
  -- new_x = current_x + (target_x - current_x) * DAMPING

--Turn on ease tracking automatically:
game_meta:register_event("on_started", function(game)
  game.activate_ease_tracking = true
end)


--Overwrite "Start Tracking Hero" function so it won't un-do the easing camera when called:
local unmod_start_tracking = camera_meta.start_tracking

function camera_meta:start_tracking(entity)
  local camera = self
  local game = self:get_game()
  if entity:get_type() == "hero" and game.activate_ease_tracking then
    camera:ease_track_hero(entity)
  else
    unmod_start_tracking(self, entity)
  end
end


--Start tracking the hero whenever the map's transition is finished:
map_meta:register_event("on_opening_transition_finished", function(map)
  local game = map:get_game()
  if game.activate_ease_tracking then
    map:get_camera():ease_track_hero(map:get_hero())
  end
end)


--HACK:
--Right now, taking a teleporter to a destination on the same map ignores any fade in/out transition while easing camera is one, causing a rough transition.
--This deactivates the ease tracking when you activate a teleporter, so the fade still works
tele_meta:register_event("on_activated", function(tele, hero)
  local game = tele:get_game()
  local map = tele:get_map()
  local map_id = map:get_id()
  local dest_map_id = tele:get_destination_map()
  local dest_name = tele:get_destination_name()
  if (map_id == dest_map_id) and (tele:get_transition() == "fade") and (dest_name ~= "_same" and dest_name ~= "_side") then
    local camera = map:get_camera()
    local dest = map:get_entity(dest_name)
    dest:register_event("on_activated", function(_, hero)
      camera:ease_track_hero(hero)
    end)
    unmod_start_tracking(camera, hero)
  end
end)


--Wrapper function, will call the particular method of camera easing that we want to use:
function camera_meta:ease_track_hero(hero)
  local camera = self
  local game = camera:get_game()
  --game.activate_ease_tracking is our on/off switch
  if not game.activate_ease_tracking then return end
  --Target movements method:
  camera:ease_track_hero_target_cam_movement(hero)
  camera.target_manual_ease_tracking = true
  --Focus entity method:
  --camera:ease_track_hero_focus_target(hero)
  --Straight movements method:
  --camera:ease_track_hero_manual_cam_movement(hero)
  --camera.straight_manual_ease_tracking = true
end


-----------------------------------------------------------------------------------------------------------------------
--Method 2:
--Set a manual movement, but a target movement instead of a straight one
-----------------------------------------------------------------------------------------------------------------------
function camera_meta:ease_track_hero_target_cam_movement(hero)
  --print("Debug: start easing")
  local camera = self
  camera:start_manual()
  -- Store target for easing
  camera.target_hero = hero
  --Create movement to manipulate on map update:
  camera.easing_movement = sol.movement.create("target")
  local game = hero:get_map():get_game()
  game.pause_ease_tracking = false
  camera.easing_movement:set_smooth(false)
  camera.easing_movement:start(camera)
end


function camera_meta:set_lookahead_hero_stopped_position(x, y, z)
  local camera = self
  camera.lookahead_hero_stopped_position = {x=x, y=y, z=z}
end

function camera_meta:get_lookahead_hero_stopped_position()
  local camera = self
  if camera.lookahead_hero_stopped_position then
    return camera.lookahead_hero_stopped_position.x, camera.lookahead_hero_stopped_position.y, camera.lookahead_hero_stopped_position.z
  else
    return camera:get_map():get_hero():get_position()
  end
end


function camera_meta:get_lead_distance()
  local camera = self
  local hero = camera.target_hero
  local MOVING_LOOKAHEAD = 24
  local AIM_LOOKAHEAD = 48
  local dist = 0
  if not hero then
    dist = 0
  else
    local m = hero:get_movement()
    local state, sob = hero:get_state()
    if state == "custom" then state = sob:get_description() end
    if state == "aiming" then
      --Aiming
      dist = AIM_LOOKAHEAD
    elseif state == "dashing" or state == "dash_recovery" then
      dist = MOVING_LOOKAHEAD
    elseif m and m:get_speed() > 40 then
      --Walking/dashing/etc
      if (hero:get_distance(camera:get_lookahead_hero_stopped_position()) > 20 ) then
        dist = MOVING_LOOKAHEAD
      else
        dist = 0
      end
    elseif m then
      --Standing still
      dist = 0
      --Mark hero position so lookahead can only kick in once they move a minim distance from their stopped position
      camera:set_lookahead_hero_stopped_position(hero:get_position())
    end
  end
  return dist
end


function camera_meta:get_lead_angle(hero)
  local dir = hero:get_direction()
  local hero_m = hero:get_movement()
  local state, sob = hero:get_state()
  local angle = dir * math.pi / 2
  if state == "custom" then state = sob:get_description() end
  if state == "aiming" then
    angle = hero:get_aim_angle()
  else
    if hero_m and hero_m:get_speed() > 0 then angle = hero_m:get_angle() end
  end
  return angle
end


map_meta:register_event("on_update", function(map)
  local CAMERA_STIFFNESS = 4
  local game = map:get_game()
  if not game.activate_ease_tracking then return end
  if game.pause_ease_tracking then return end
  local camera = map:get_camera()
  if not camera.target_manual_ease_tracking then return end
  if not camera.easing_movement then return end
  local hero = camera.target_hero
  --camera.easing_movement:start(camera)

  --  Test: if the camera isn't in the same region : teleport it to hero
  if not camera:is_in_same_region(hero) then
    --print("Debug: Not in same region hack")
    camera.easing_movement:set_xy(camera:get_position_to_track(hero))
  end

  -- Calculate target position based on hero direction (to have some lookahead):
  local hx, hy = hero:get_position()
  local cx, cy = camera:get_position()
  local w, h = camera:get_size()
  local angle = camera:get_lead_angle(hero)
  local lead_distance = camera:get_lead_distance()
  local dx = math.cos(angle) * lead_distance
  local dy = math.sin(angle) * lead_distance * -1
  local ideal_x, ideal_y = hx + dx, hy + dy
  local tx, ty = camera:get_position_to_track(ideal_x, ideal_y)
  
  local mx,my = camera.easing_movement:get_xy()
  --print("target", tx, ty, mx, my, camera.easing_movement:is_suspended(), camera:get_state())
  camera.easing_movement:set_target(tx, ty)
  local distance = sol.main.get_distance(cx, cy, tx, ty)
  camera.easing_movement:set_speed(distance* CAMERA_STIFFNESS)
end)

--Workarounds:
--The camera can't cross separators, which is good.
--However, when the hero crosses, we will need to move the camera over there lest we loose him
separator_meta:register_event("on_activating", function(separator)
  local game = separator:get_game()
  if not game.activate_ease_tracking then return end
  if game.pause_ease_tracking then return end
  --print("separator_on_activating_workaround exe")
  local map = separator:get_map()
  local camera = map:get_camera()
  local hero = map:get_hero()
  game.pause_ease_tracking = true
  camera.easing_movement:stop()
  unmod_start_tracking(camera, hero)
end)

separator_meta:register_event("on_activated", function(separator)
  local game = separator:get_game()
  if not game.activate_ease_tracking then return end
  --print("separator_on_actived_workaround exe")
  game.pause_ease_tracking = false
  local map = separator:get_map()
  local camera = map:get_camera()
  local hero = map:get_hero()
  camera:ease_track_hero(hero)
end)