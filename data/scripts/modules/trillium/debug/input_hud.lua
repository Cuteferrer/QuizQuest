--[[
By Max Mraz, licensed MIT

Simple little HUD overlay that shows inputs received from keyboard or controller
--]]

local menu = {}

local num_shown = 10
local command_history = {}
local cmd_surfaces = {}
local input_history = {}
local input_surfaces = {}
local axis_cooldowns = {}

for i = 1, num_shown do
  local font_val = 255 - (i * 20)
  local font_color = {font_val, font_val, font_val}
  cmd_surfaces[i] = sol.text_surface.create{
    font = "enter_command", font_size = 16,
    font_color = font_color,
  }
  input_surfaces[i] = sol.text_surface.create{
    font = "enter_command", font_size = 16,
    font_color = font_color,
  }
  cmd_surfaces[i]:set_opacity(font_val + 20)
  input_surfaces[i]:set_opacity(font_val + 20)
end


function menu:on_command_pressed(cmd)
  table.insert(command_history, 1, cmd)
  menu:update_surfaces()
end

function menu:on_key_pressed(key)
  table.insert(input_history, 1, key)
  menu:update_surfaces()
end

function menu:on_joypad_button_pressed(btn)
  table.insert(input_history, 1, btn)
  menu:update_surfaces()
end

function menu:on_mouse_pressed(btn, x, y)
  table.insert(input_history, 1, "Mouse:" .. btn)
  menu:update_surfaces()
end

function menu:on_joypad_axis_moved(axis, state)
  --if axis == "right_x" or axis == "right_y" or axis == "left_x" or axis == "left_y" then return end
  if axis_cooldowns[axis] then return end
  axis_cooldowns[axis] = true
  sol.timer.start(menu, 500, function()
    axis_cooldowns[axis] = nil
  end)
  table.insert(input_history, 1, axis)
  menu:update_surfaces()
end


function menu:update_surfaces()
  for i = 1, num_shown do
    cmd_surfaces[i]:set_text(command_history[i])
  end
  for i = 1, num_shown do
    input_surfaces[i]:set_text(input_history[i])
  end
end


function menu:on_draw(dst)
  for i, surface in ipairs(input_surfaces) do
    surface:draw(dst, 320, 56 + i * 16)
  end
end


return menu
