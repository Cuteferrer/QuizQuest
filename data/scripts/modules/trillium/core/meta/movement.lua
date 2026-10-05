--[[
Created by Max Mraz, licensed MIT

Extra functions for movements:
--]]

local m_meta = sol.main.get_metatable"movement"
local straight_m_meta = sol.main.get_metatable"straight_movement"
local circle_m_meta = sol.main.get_metatable"circle_movement"


local function set_any_movement_speed(m, new_speed)
  local m_type = m:get_type()
  if (m_type == "circle_movement") then
    m:set_angular_speed(new_speed)
  else
    m:set_speed(new_speed)
  end
end


local function set_acceleration(m, context, acceleration, limit)
  assert(context and type(acceleration) == "number", "You didn't send the right arguments to movement:set_acceleration(timer_context_entity, acceleration, [speed_limit])")
  local m_type = m:get_type()
  if m.acceleration_timer then m.acceleration_timer:stop() end
  local is_positive = acceleration > 0
  m.acceleration_timer = sol.timer.start(context, 10, function()
    if not m then return end --I think this like literally never happens
    local cur_speed = (m_type == "circle_movement") and m:get_angular_speed() or m:get_speed()
    local new_speed = cur_speed + acceleration
    --only set speed if new speed is within limit:
    if (limit and is_positive and (new_speed <= limit)) or (limit and (is_positive == false) and (new_speed >= limit)) or (not limit) then
      set_any_movement_speed(m, new_speed)
    end
    if limit then
      if (is_positive and new_speed < limit) or (not is_positive and new_speed > limit) then return true end
    end
  end)
end

straight_m_meta.set_acceleration = set_acceleration
circle_m_meta.set_acceleration = set_acceleration

