local menu = {}
local font, font_size = sol.modules.get_object("language_manager"):get_dialog_font()

local panel_size = {width = 320, height = 64}
local border = sol.surface.create(panel_size.width + 2, panel_size.height + 2)
local background = sol.surface.create(panel_size.width, panel_size.height)

local text_surface = sol.text_surface.create{
  font = font, font_size = font_size,
}

function menu:update()
  border:clear()
  border:fill_color{140, 130, 125, 255}
  background:clear()
  background:fill_color{0,0,0,255}
  text_surface:draw(background, 16, panel_size.height / 2)
  background:draw(border, 1, 1)
end

local draw_x = 416 / 2 - panel_size.width / 2
--local draw_y = 240 / 2 - panel_size.height / 2
local draw_y = -4

function menu:on_draw(dst)
  border:draw(dst, draw_x - 1, draw_y - 1)
end


function menu:on_started()
  text_surface:set_text_key("menu.controls.input_capture_warning")
  menu:update()
end

function menu:invalid_input()
  text_surface:set_text_key("menu.controls.invalid_input")
  print"Button Remapping: Invalid input"
  menu:update()
end

function menu:invalid_command()
  text_surface:set_text_key("menu.controls.invalid_command")
  print"Button Remapping: Invalid command"
  menu:update()
end

function menu:invalid_control_type()
  text_surface:set_text_key("menu.controls.invalid_control_type")
  print"Button Remapping: Wrong control type input for the type displayed"
  menu:update()
end


return menu
