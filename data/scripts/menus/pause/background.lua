--[[
Darkens and blurs background while paused
--]]

local menu = {}

local blur_shader = sol.shader.create("frosted_glass")

local dark_surface = sol.surface.create()
-- dark_surface:fill_color{0,0,0,20}
local cam_surface

function menu:on_started()
  local game = sol.main.get_game()
  cam_surface = game:get_map():get_camera():get_surface()
  cam_surface:set_shader(blur_shader)
end

function menu:on_finished()
  cam_surface:set_shader(nil)
end

function menu:on_draw(dst)
  dark_surface:draw(dst)
end

return menu