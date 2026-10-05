--[[
Created by Max Mraz, licensed MIT
A panel that will display a message, and have a "confirm" or "cancel" option.
Will call a passed function with selected option.
--]]

local nineslice = sol.modules.get_object("trilmenu_nineslice")
local screen_width, screen_height = sol.video.get_quest_size()

local factory = {}


function factory.new(props)
  props = props or {}
  local callback = props.callback --Required!
  local message_key = props.message_key or "options.command.confirm"
  local response_strings = props.response_strings or {"options.command.confirm", "options.command.cancel"}
  local default_option = props.default_option or 2 --defaults to "cancel"

  local font, font_size = sol.modules.get_object("language_manager").get_menu_font()

  local menu = {}
  local menu_width, menu_height = 320, 56
  local cursor_width = menu_width / 4 --default width
  menu.cursor_index = default_option
  menu.bg = nineslice.get_surface{
    width = menu_width, height = menu_height,
    source_png = "menus/panel_blocks/small.png",
    tile_width = 8, tile_height = 8,
  }
  menu.message_surface = sol.text_surface.create{
    font = font, font_size = font_size, horizontal_alignment = "center",
    text_key = message_key,
  }
  menu.confirm_surface = sol.text_surface.create{
    font = font, font_size = font_size, horizontal_alignment = "right",
    text_key = response_strings[1],
  }
  menu.cancel_surface = sol.text_surface.create{
    font = font, font_size = font_size, horizontal_alignment = "left",
    text_key = response_strings[2],
  }

  --Reset cursor width based on given strings:
  local longer_string_width = math.max(menu.confirm_surface:get_size(), menu.cancel_surface:get_size())
  cursor_width = longer_string_width + 2

  local cursor = sol.surface.create(cursor_width, 1)
  cursor:fill_color({255,255,255})

  

  --Draw 'em
  menu.message_surface:draw(menu.bg, menu_width / 2, 16)
  menu.confirm_surface:draw(menu.bg, menu_width / 2 - 8, 36)
  menu.cancel_surface:draw(menu.bg, menu_width / 2 + 8, 36)


  function menu:on_draw(dst)
    menu.bg:draw(dst, screen_width / 2 - menu_width / 2, screen_height / 2 - menu_height / 2 )
    if menu.cursor_index == 1 then
      cursor:draw(dst, screen_width / 2 - cursor_width - 8, screen_height / 2 - menu_height / 2 + 42)
    elseif menu.cursor_index == 2 then
      cursor:draw(dst, screen_width / 2 + 8, screen_height / 2 - menu_height / 2 + 42)
    end
  end


  function menu:set_cursor_index(new_index)
    menu.cursor_index = new_index
  end


  function menu:on_command_pressed(cmd)
    if cmd == "left" then
      menu:set_cursor_index(1)
    elseif cmd == "right" then
      menu:set_cursor_index(2)
    elseif cmd == "confirm" then
      callback(menu.cursor_index)
      sol.menu.stop(menu)
    end
    return true --prevent input propagation
  end


  return menu

end



return factory
