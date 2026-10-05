--[[
Created by Max Mraz, licensed MIT
A menu component that shows a number - left and right inputs will increment this number by a given increment (default 1)

Example usage:
local incrementer = sol.modules.get_object("trilmenu_component_incrementer").create({
  x = 8,
  y = 50,
  initial_amount = 5,
  step = 5,
  min = 0,
  max = 100,
})
function incrementer:on_changed(amount)
  --do something with amount
end

sol.menu.start(context, incrementer)

--]]


local multi_events = sol.modules.get_object("multi_events")
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()

local menu_prototype = {}
multi_events:enable(menu_prototype)

local menu_metatable = {__index = menu_prototype}


menu_prototype:register_event("on_started", function(menu)
  menu.background = sol.surface.create(menu.width, menu.height)
  if menu.background_png then menu.background = sol.surface.create(menu.background_png) end
  if menu.background_color then menu.background:fill_color(menu.background_color) end
  menu.surface = sol.surface.create(menu.width, menu.height)
  menu.text_surface = sol.text_surface.create{
    font = font, font_size = font_size,
    horizontal_alignment = "center",
    vertical_alignment = "bottom",
    vertical_alignment = "top",
  }

  menu.amount = menu.initial_amount
  if menu.get_initial_amount then menu.amount = menu.get_initial_amount() end

  menu:update()
end)


function menu_prototype:on_draw(dst)
  local menu = self
  menu.surface:draw(dst, menu.x, menu.y)
end


function menu_prototype:update()
  local menu = self
  menu.surface:clear()
  menu.background:draw(menu.surface)
  menu.text_surface:set_text(menu.amount)
  menu.text_surface:draw(menu.surface, menu.text_offset.x, menu.text_offset.y)
end


function menu_prototype:increment(direction) --direction can be 1 or -1
  local menu = self
  local new_amount = menu.amount + menu.step * direction
  if new_amount < menu.min then
    new_amount = menu.min
    sol.audio.play_sound("wrong")
  elseif new_amount > menu.max then
    new_amount = menu.max
    sol.audio.play_sound("wrong")
  end
  sol.audio.play_sound("cursor")
  menu.amount = new_amount
  menu:update()
end


function menu_prototype:alert_change()
  local menu = self
  if menu.on_changed then
    menu:on_changed(menu.amount)
  else
    print("Warning: Incrementer component was created which has no effect. Define component:on_changed(amount) for any incrementer components. Otherwise it is useless.")
  end
end


function menu_prototype:on_command_pressed(command)
  local menu = self
  handled = false
  if command == "left" then
    menu:increment(-1)
    menu:alert_change()
    handled = true
  elseif command == "right" then
    menu:increment(1)
    menu:alert_change()
    handled = true
  elseif command == "attack" or command == "cancel" or command == "confirm" or command == "action" or command == "up" or command == "down" then
    handled = true
    sol.menu.stop(menu)
  end
  return handled
end




local factory = {}

function factory.create(config)
  local menu = {}
  config = config or {}
  menu.x, menu.y = config.x or 0, config.y or 0
  menu.width = config.size and config.size.width or 32
  menu.height = config.size and config.size.height or 32
  menu.background_color = config.background_color
  menu.background_png = config.background_png --note, this will change the size of the menu to be the size of the background
  config.text_offset = config.text_offset or {x = 16, y = 8}
  menu.text_offset = {x = config.text_offset.x, y = config.text_offset.y}
  menu.initial_amount = config.initial_amount or 0
  menu.max = config.max
  menu.min = config.min
  menu.step = config.step

  setmetatable(menu, menu_metatable)

  return menu

  --[[ Sample config:
  {
    x = 8,
    y = 50,
    initial_amount = 5,
    step = 5,
    min = 0,
    max = 100,
  }
  --]]
end

return factory

