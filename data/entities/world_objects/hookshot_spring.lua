local entity = ...
local game = entity:get_game()
local map = entity:get_map()


local LAUNCH_SPEED = 250
local LAUNCH_DIST = 98


local function launch_collision(entity, other)
    if other:get_type() == "hero" --and ( other:get_direction() == other:get_direction4_to(entity) )
    and (other:get_state() == "custom") and (other:get_state_object():get_description() == "hookshot") then
      local hero = other
      game:get_item("inventory/hookshot").hook:remove() --to unhook from target without ending hookshot state
      local state = game:get_item("inventory/feather"):get_jumping_state()
      hero:start_state(state) --start jumping directly from hookshot state
      hero:set_animation"jumping_arc"
      sol.audio.play_sound"jump"
      --Slide hero to center position to make jump length consistent:
      local m = sol.movement.create"target"
      m:set_target(entity)
      m:set_speed(300)
      m:start(hero, function()
        local m = sol.movement.create"straight"
        m:set_angle(hero:get_direction() * math.pi / 2)
        m:set_speed(entity.launch_speed or LAUNCH_SPEED)
        m:set_max_distance(entity.launch_distance or LAUNCH_DIST)
        m:start(hero, function()
          hero:unfreeze()
        end)
        function m:on_obstacle_reached()
          m:stop()
          hero:unfreeze()
        end
      end)
    end
end


entity:register_event("on_created", function()
  entity.hookshot_target = true
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by("hero", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity.launch_distance = tonumber(entity:get_property("launch_distance") or LAUNCH_DIST)
  entity.launch_speed = LAUNCH_SPEED
  entity:add_collision_test("touching", function(entity, other) launch_collision(entity, other) end)
  entity:add_collision_test("sprite", function(entity, other) launch_collision(entity, other) end)

  entity:set_size(16, 24)
  entity:set_origin(8, 21)
end)


function entity:react_to_hookshot(hook)
  entity:create_launcher_hitbox()
  --[[
  local m = entity:get_movement()
  if m and m:get_speed() > 5 then
    local init_speed = m:get_speed()
    m:set_speed(5)
    sol.timer.start(entity, 1000, function()
      m:set_speed(init_speed)
    end)
  end
  --]]
end


function entity:create_launcher_hitbox()
  local bleed = 0
  local x, y, z = entity:get_position()
  local w, h = entity:get_size()
  local launcher = map:create_custom_entity{
    x = x - bleed, y = y - bleed, layer = z,
    width = w + bleed * 2, height = h + bleed * 2, direction=0,
  }
  launcher:set_origin(8, 21)
  launcher:add_collision_test("overlapping", function(entity, other)
    if other:get_type() == "hero" then
      launcher:remove()
      launch_collision(entity, other)
    end
  end)
end

