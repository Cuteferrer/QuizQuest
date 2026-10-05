--[[
Created by Max Mraz, licensed MIT
Use this as an element within menus. It creates a box that will cycle left and right though a list of options that you pass to it.

Usage: require this factory to create a component and pass in config. Then, define the on_changed() event, and optionally the get_initial_index() function

local swiper = sol.modules.get_object("trilmenu_component_swiper").create({
  x = 8,
  y = 50,
  options = {
    {value = "stereo", string_key = "menu.options.sound.stereo"},
    {value = "mono", string_key = "menu.options.sound.mono"},
    {value = "surround", string_key = "menu.options.sound.surround"},
  },
})

function swiper:on_changed(selection)
  --do something like game:set_value("some_thing", selection)
end


OPTIONAL FUNCTIONS:
- You can define the function: menu:get_initial_index() which should return an integer, if this exists then the menu will call it 
  Use this to check your current settings/values to make sure the component displays the proper option when it loads up

- You can also use swiper:get_options() to get the swiper's list of options. This might be useful when setting get_initial_index
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
    vertical_alignment = "top",
  }

  menu.index = menu.initial_index
  if menu.get_initial_index then menu.index = menu.get_initial_index() end

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
  local text_key = menu.options[menu.index].string_key
  menu.text_surface:set_text_key(text_key)
  menu.text_surface:draw(menu.surface, menu.text_offset.x, menu.text_offset.y)
end


function menu_prototype:cycle_option(direction) --direction can be 1 or -1
  local menu = self
  local new_index = menu.index + (1 * direction)
  if new_index > #menu.options then new_index = 1
  elseif new_index <= 0 then new_index = #menu.options end
  sol.audio.play_sound("cursor")
  menu.index = new_index
  menu:update()
end


function menu_prototype:alert_selection_change()
  local menu = self
  local selection = menu.options[menu.index].value
  if menu.on_changed then
    menu:on_changed(selection)
  else
    print("Warning: Swiper component was created which has no effect. Define component:on_changed(selection) for any swiper components")
  end
end


function menu_prototype:on_command_pressed(command)
  local menu = self
  handled = false
  if command == "left" then
    menu:cycle_option(-1)
    menu:alert_selection_change()
    handled = true
  elseif command == "right" then
    menu:cycle_option(1)
    menu:alert_selection_change()
    handled = true
  elseif command == "attack" or command == "cancel" or command == "confirm" or command == "action" or command == "up" or command == "down" then
    handled = true
    sol.menu.stop(menu)
  end
  return handled
end


function menu_prototype:get_options()
  return menu.options
end




local factory = {}

function factory.create(config)
  local menu = {}
  assert(config.options, "You cannot create a swiper component without passing at least config.options")
  config = config or {}
  menu.options = config.options --This is a required value
  menu.x, menu.y = config.x or 0, config.y or 0
  menu.width = config.size and config.size.width or 208
  menu.height = config.size and config.size.height or 16
  menu.background_color = config.background_color
  menu.background_png = config.background_png --note, this will change the size of the menu to be the size of the background
  config.text_offset = config.text_offset or {x = 0, y = 0}
  menu.text_offset = {x = config.text_offset.x, y = config.text_offset.y}
  menu.initial_index = config.initial_index or 1

  setmetatable(menu, menu_metatable)

  return menu

  --[[ Sample config:
  {
    x = 8,
    y = 50,
    options = {
      {value = "stereo", string_key = "menu.options.sound.stereo"},
      {value = "mono", string_key = "menu.options.sound.mono"},
      {value = "surround", string_key = "menu.options.sound.surround"},
    },
  }
  --]]
end

return factory
