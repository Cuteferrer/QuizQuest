--[[
Miscellaneous angle functions
--]]

--Rounds a number to the nearest integer
function sol.main.round(x, step)
  step = step or 1
return math.floor(x / step + 0.5) * step
end


--Gets direction4 for any angle
function sol.main.get_direction4(angle)
  local rounded_angle = sol.main.round(angle, math.pi / 2)
  return math.floor(rounded_angle / (math.pi / 2)) % 4
end

--Get direction8 for any angle
function sol.main.get_direction8(angle)
  local rounded_angle = sol.main.round(angle, math.pi / 4)
  return math.floor(rounded_angle / (math.pi / 4)) % 8
end


--Get normalized difference between angles:
local function normalize_angle(angle)
  return (angle + math.pi) % math.pi * 2
end

function sol.main.get_angle_difference(a, b)
  a = normalize_angle(a)
  b = normalize_angle(b)
  return math.abs(a - b)
end


--Returns the current direction8 of an analog stick by passing its horizontal and vertical axes. -1 means that the hat is centered. 0 to 7 indicates that the hat is in one of the eight main directions.
function sol.main.get_axis_direction(horiz_axis, vert_axis)
  local horiz = sol.input.get_joypad_axis_state(horiz_axis)
  local vert = sol.input.get_joypad_axis_state(vert_axis)
  local orientation = horiz .. ", " .. vert
  local direction8 = {
    ["0, 0"] = -1,
    ["1, 0"] = 0,
    ["1, -1"] = 1,
    ["0, -1"] = 2,
    ["-1, -1"] = 3,
    ["-1, 0"] = 4,
    ["-1, 1"] = 5,
    ["0, 1"] = 6,
    ["1, 1"] = 7,
  }
  return direction8[orientation]
end


local hero_meta = sol.main.get_metatable("hero")

function hero_meta:get_angle_to_mouse()
  local hero = self
  local map = hero:get_map()
  local mx, my = sol.input.get_mouse_position()
  local hx, hy = hero:get_position()
  --hero coordinates are relative to map, while mouse is relative to screen. So we need to subtract the camera's coordinates
  local cx, cy = map:get_camera():get_position()
  hx = hx - cx
  hy = hy - cy
  return math.atan2(mx-hx , my-hy) - math.pi / 2
end

