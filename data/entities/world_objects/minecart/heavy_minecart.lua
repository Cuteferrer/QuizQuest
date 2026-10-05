local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity.weight = tonumber(entity:get_property("weight") or 1)
  entity.is_track_vehicle = true --will get redirected by track corners
  entity:set_traversable_by(false)
  entity:set_traversable_by("hero", function(entity, other) return other:overlaps(entity) end)
  entity:set_traversable_by("enemy", function(entity, other) return other:overlaps(entity) end)
  entity:set_drawn_in_y_order(true)
  entity.hookshot_target = true

  entity.collided_switches = {}

  entity:add_collision_test("overlapping", function(entity, other)
    if other:get_type() == "switch" and other:is_walkable() then
      entity:press_switch(other)
    elseif other:get_type() == "hero" or other:get_type() == "enemy" then
      entity:push_other(other)
    end
  end)

  --[[
  entity:add_collision_test("facing", function(entity, other)
    if other:get_type() == "hero" and other:get_state() == "pushing" then
      local facing_dir = entity:get_direction()
      local dir = other:get_direction4_to(entity)
      local parallel = (dir - facing_dir) % 2 ~= 1
      if not parallel then return end

      sol.timer.start(entity, 300, function()
        if other:get_state() == "pushing" then
          other:unfreeze()
          entity:roll(dir)
        end
      end)
    end
  end)
  --]]
end


function entity:push_other(other)
  local m = entity:get_movement()
  if m and m:get_speed() > 0 then
    local angle = m:get_angle()
    local dx, dy = math.cos(angle), math.sin(angle) * -1
    local x, y, z = other:get_position()
    local is_obstacle = other:test_obstacles(dx, dy)
    if not is_obstacle then
      other:set_position(x + dx, y + dy, z)
    end
  end
end


--
function entity:on_interaction()
  local hero = map:get_hero()
  local facing_dir = entity:get_direction()
  local dir = hero:get_direction4_to(entity)

  local parallel = (dir - facing_dir) % 2 ~= 1
  local strong_enough = game:get_ability("lift") >= entity.weight

  if parallel and strong_enough then
    entity:roll(dir)
  elseif not strong_enough then
    game:start_dialog("game.too_heavy")
  end

end
--]]


function entity:react_to_hookshot(hook)
  local dir = entity:get_direction4_to(hook)
  entity:roll(dir)
end


function entity:roll(dir)
  --local start_speed = 53
  --local acceleration = 1
  --local start_speed = 159
  --local acceleration = 3
  local start_speed = 90
  local acceleration = 2
  local stop_threshold = 10
  local m = sol.movement.create("straight")
  m:set_angle(dir * math.pi / 2)
  m:set_speed(start_speed)
  m:set_max_distance(48)
  m:set_smooth(false)
  m:start(entity)

  function m:on_position_changed()
    local new_speed = m:get_speed() - acceleration
    if new_speed > stop_threshold then
      m:set_speed(new_speed)
    else
      m:stop()
    end
  end

  if entity.on_rolled then
    entity:on_rolled()
  end
end


function entity:on_corner_redirect()
  --called when redirected by track corners
  local m = entity:get_movement()
  if m then
    m:set_max_distance(m:get_max_distance() + 16)
    m:set_speed(m:get_speed() + 60)
  end
end


function entity:press_switch(switch)
  if entity.collided_switches[switch] then return end
  entity.collided_switches[switch] = true
  switch:activate()
  sol.timer.start(switch, 50, function()
    if not entity:overlaps(switch) then
      switch:set_activated(false)
      entity.collided_switches[switch] = nil
    else
      return true
    end
  end)
end

