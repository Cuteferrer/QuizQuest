--[[
Created by Max Mraz, licensed MIT

Reads a dialog and presents it as scrolling credits
Special lines you can do in the dialog file:

$img=menus/title_logo.png --this will show an image instead of text. Make sure you leave enough blank lines below it!
Job Title|John Lastname --if you put a vertical pipe in the middle of a line, that will get centered there.

--]]

--Config:
local credits_dialog_id = "credits.credits"
local jobtitle_gap = 16 --how far between a job title and person's name


local menu = {}
local hold_to_factory = sol.modules.get_object("trilmenu_component_confirmation_hold")
local screen_width, screen_height = sol.video.get_quest_size()
local font, font_size, line_height = sol.modules.get_object("language_manager"):get_menu_font()


local scroll_speed = 30
local padding = 16
local hold_to_widget_config = {
  callback = function()
    menu.callback()
  end,
  position = {x=16, y=200},
  text_string = "game.hud_messages.hold_to_skip",
  hidden = true,
}
local hold_to_widget = hold_to_factory.create(hold_to_widget_config)



function sol.main.start_credits(callback)
  callback = callback or function() sol.menu.stop(menu) print("Warning: No callback for credits end, just fyi") end
  menu.callback = callback
  sol.menu.start(sol.main, menu)
end


function menu:build()
  menu.bg = sol.surface.create()
  menu.bg:fill_color{0,0,0}

  local text_string = sol.language.get_dialog(credits_dialog_id).text
  local lines = {}
  for s in text_string:gmatch("([^\n]*)\n") do --break out each line, including empty lines
      table.insert(lines, s)
  end


  --Create credits surface:
  menu.credits_height = (#lines * 16) + padding * 2 + (screen_height)  --lines + padding for top and bottom + empty space at the bottom (so the words can scroll fully offscreen)
  menu.credits_surface = sol.surface.create(screen_width, menu.credits_height)
  --Draw lines onto surface:
  for i, line in ipairs(lines) do
    line = menu:variable_line_sub(line)
    local line_surface = menu:create_line_surface(line)
    local draw_x = screen_width / 2 + (line_surface.x_offset or 0)
    local draw_y = line_height * i + padding
    if line_surface.justify_left then draw_x = 0 end
    line_surface:draw( menu.credits_surface, draw_x, draw_y )
  end

end


function menu:variable_line_sub(line)
  --In case we want to have any variables in the credits
  return line
end


function menu:create_line_surface(line)
  local surface
  --first, make sure this isn't actually an image:
  local img_id = line:match('$img=(.+)')
  local title_and_name = line:match('|')

  --Image
  if img_id then
    surface = sol.surface.create(img_id)
    local w, h = surface:get_size()
    surface.x_offset = (w / 2 * -1)

  --"Job Title | John Lastname" situation. If so, make two surfaces, draw them onto an intermediary surface, and return that
  elseif title_and_name then
    local line_width = screen_width
    surface = sol.surface.create(line_width, 48)
    surface.justify_left = true --this one isn't a text surface that can be drawn centered
    local title = line:match('(.+)|')
    local person = line:match('|(.+)')
    local title_surface = sol.text_surface.create{
      font = font,
      font_size = font_size,
      horizontal_alignment = "right",
      vertical_alignment = "top",
      text = title,
    }
    local person_surface = sol.text_surface.create{
      font = font,
      font_size = font_size,
      horizontal_alignment = "left",
      vertical_alignment = "top",
      text = person,
    }
    title_surface:draw(surface, line_width / 2 - jobtitle_gap / 2, 0)
    person_surface:draw(surface, line_width / 2 + jobtitle_gap / 2, 0)

  --Normal text line
  else
    surface = sol.text_surface.create{
      font = font,
      font_size = font_size,
      horizontal_alignment = "center",
      text = line,
    }
  end
  return surface
end


function menu:on_started()
  menu:build()
  local m = sol.movement.create"straight"
  m:set_angle(math.pi / 2)
  m:set_speed(scroll_speed)
  m:set_max_distance(menu.credits_height)
  m:start(menu.credits_surface, function()
    menu.callback()
  end)
  menu.scroll_movement = m
  --Hold to skip widget:
  sol.menu.start(menu, hold_to_widget)
  sol.menu.bring_to_front(hold_to_widget)
end


function menu:on_draw(dst)
  menu.bg:draw(dst)
  menu.credits_surface:draw(dst, 0, screen_height)
end


function menu:on_command_pressed(command)
  return true --intercept all commands
end




return menu
