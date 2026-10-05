--[[
Created by Max Mraz. Licensed MIT

Use this as an element within menus. It creates a slider that can go from 0 - 100.

Usage:

local slider = sol.modules.get_object("trilmenu_component_slider").create{
  x = 190, y = 96,
  size = {width = 108, height = 16},
  line_length = 100,
  background_color = {0,0,0,115},
}
function slider:process_change(new_level)
  --set things based on new level
end
sol.menu.start(current_menu, slider)

--]]


local multi_events = sol.modules.get_object("multi_events")

local menu_prototype = {}
multi_events:enable(menu_prototype)

local menu_metatable = {__index = menu_prototype}


menu_prototype:register_event("on_started", function(self)
  local menu = self

  menu.background = sol.surface.create(menu.width, menu.height)
  if menu.background_png then menu.background = sol.surface.create(menu.background_png) end
  if menu.background_color then menu.background:fill_color(menu.background_color) end
  menu.line = sol.surface.create(menu.line_length, 1)
  menu.line:fill_color(menu.slider_color)
  menu.line:draw(menu.background, menu.line_offset.x, menu.line_offset.y)
  menu.slider = sol.surface.create(2, 8)
  menu.slider:fill_color(menu.slider_color)

  menu.slider_level = menu.slider_level or menu.initial_position

end)


function menu_prototype:on_draw(dst)
  local menu = self
  menu.background:draw(dst, menu.x, menu.y)
  menu.slider:draw(dst, menu.x + menu.line_offset.x + menu.slider_level / menu.slider_ratio, menu.y + menu.line_offset.y - 3)
end



function menu_prototype:set_position(position)
  local menu = self
  menu.slider_level = position
end


function menu_prototype:adjust_slider(amount)
  local menu = self
  local new_level = menu.slider_level + amount
  if new_level < 0 then new_level = 0
  elseif new_level > 100 then new_level = 100 end
  menu.slider_level = new_level

  if menu.process_change then
    menu:process_change(menu.slider_level)
  end
end




local factory = {}

function factory.create(config)
  local menu = {}
  config = config or {}
  menu.x, menu.y = config.x or 0, config.y or 0
  menu.increment_size = config.increment_size or 10
  menu.width = config.size and config.size.width or 58
  menu.height = config.size and config.size.height or 16
  menu.line_color = config.line_color or {115,155,155}
  menu.slider_color = config.slider_color or {255,255,255}
  menu.line_length = config.line_length or 50
  menu.slider_ratio = 100 / menu.line_length
  menu.line_offset = config.line_offset or {x=4, y=8}
  menu.initial_position = config.initial_position or 50
  menu.background_color = config.background_color
  menu.background_png = config.background_png --note, this will change the size of the menu to be the size of the background


  function menu:process_input(command)
    local handled = false
    if command == "left" then
      menu:adjust_slider(menu.increment_size * -1)
      handled = true
    elseif command == "right" then
      menu:adjust_slider(menu.increment_size)
      handled = true
    elseif command == "confirm" or command == "cancel" or command == "up" or command == "down" then
      sol.menu.stop(menu)
      handled = true
    end
    return handled
  end

  setmetatable(menu, menu_metatable)

  menu.on_command_pressed = menu.process_input

  return menu
end

return factory

