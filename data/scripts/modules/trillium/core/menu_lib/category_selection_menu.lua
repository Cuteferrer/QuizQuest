--A menu to hold multiple grid menus (mainly for the grid menus to serve as categories of an inventory or the like), allowing to switch back and forth between the grid menus
--Licensed MIT, created by Max Mraz

local multi_events = sol.modules.get_object("multi_events")
local default_settings = require("scripts/modules/trillium/core/menu_lib/default_settings")
local bg_9slice_manager = require("scripts/modules/trillium/core/menu_lib/nineslice_background_manager")
local menu_features_manager = require("scripts/modules/trillium/core/menu_lib/menu_features")

local factory = {}

local menu_prototype = {}
multi_events:enable(menu_prototype)

local menu_metatable = {__index = menu_prototype}

--Constants for color
local dark_color = sol.colors.ui_grey_light
local highlight_color = sol.colors.ui_off_white

menu_prototype:register_event("on_started", function(self)
  local menu = self

  --Cursor
  if not menu.cursor_index then
    menu.cursor_index = 1
  end
  menu.cursor_line = sol.surface.create(menu.cursor_width, 1)
  menu.cursor_line:fill_color(sol.colors.ui_off_white)
  menu.cursor_line:set_opacity(0)

  --Submenu L/R icons:
  --NOTE: this only works with Trillium controls manager
  local controls_manager = sol.controls.get_controls_manager()
  local sub_l_sprite, sub_l_anim = controls_manager:get_command_sprite_id("submenu_left")
  local sub_r_sprite, sub_r_anim = controls_manager:get_command_sprite_id("submenu_right")
  menu.sub_l_icon = sol.sprite.create(sub_l_sprite)
  menu.sub_l_icon:set_animation(sub_l_anim)
  menu.sub_r_icon = sol.sprite.create(sub_r_sprite)
  menu.sub_r_icon:set_animation(sub_r_anim)

  --Active Submenu
  if not menu.active_submenu then
    menu.active_submenu = {}
  end

  menu.categories_surface = sol.surface.create(menu.width, menu.height)
  menu.cat_surfaces = {}
  menu.cat_icons = {}
  
  for i, cat in pairs(menu.categories) do
    if cat.icon then
      local icon_sprite = sol.sprite.create(cat.icon)
      icon_sprite:set_color_modulation(dark_color)
      menu.cat_icons[i] = icon_sprite
    end
    if cat.name then
      --Create a surface with menu's name
      local text_key = sol.language.get_string(cat.name)
      local txt = sol.text_surface.create{
        font = menu.font,
        font_size = menu.font_size,
        vertical_alignment = "top",
        horizontal_alignment = "left",
        color = menu.font_color,
        text = text_key or cat.name,
      }
      txt:set_color_modulation(dark_color)
      menu.cat_surfaces[i] = txt
    end
  end

  menu.background_surface = sol.surface.create(menu.width, menu.height)
  menu.background_surface:fill_color(menu.background_color)
  if menu.background_png then
    menu.background_surface = sol.surface.create(menu.background_png)
  end
  if menu.background_9slice_config then
    menu.background_surface = bg_9slice_manager.get_surface(menu.background_9slice_config)
  end

  menu:update()
end)


function menu_prototype:update()
  local menu = self
  menu.categories_surface:clear()
  for i, cat in pairs(menu.categories) do
    if  menu.cat_icons[i] then
      local icon = menu.cat_icons[i]
      icon:set_color_modulation( menu.cursor_index == i and highlight_color or dark_color)
      icon:draw(menu.categories_surface, menu.category_width * (i - 1) + menu.category_width / 2 + menu.category_offset.x, menu.height - 3 + menu.category_offset.y)
    end
    if menu.cat_surfaces[i] then
      local txt = menu.cat_surfaces[i]
      --local txt_width = txt:get_size()
      txt:set_color_modulation( menu.cursor_index == i and highlight_color or dark_color)
      txt:draw(menu.categories_surface, menu.category_width * (i - 1) + menu.category_offset.x + menu.category_padding, menu.category_offset.y)
    end
  end

  local old_submenu = menu.active_submenu
  if sol.menu.is_started(old_submenu) then
    sol.menu.stop(old_submenu)
  end
  menu.active_submenu = menu.categories[menu.cursor_index].menu
  menu.active_submenu.is_child = true
  menu.active_submenu.parent_menu = menu
  sol.menu.start(menu, menu.active_submenu)

  if old_submenu.unfocused and menu.active_submenu.unfocus then
    menu.active_submenu:unfocus()
  elseif not old_submenu.unfocused and menu.active_submenu.unfocused and menu.active_submenu.focus then
    menu.active_submenu:focus()
  end

  if menu.currently_scrolling and menu.active_submenu.react_to_parent_menu_scroll then
    sol.timer.start(menu,10, function()
      menu.active_submenu:react_to_parent_menu_scroll(menu.currently_scrolling)
      menu.currently_scrolling = nil
    end)
  end

  menu.cursor_line:draw(menu.categories_surface, menu.cursor_index * menu.category_width - (menu.category_width / 2) - (menu.cursor_width / 2), menu.height - 1 + menu.category_offset.y)

end


function menu_prototype:scroll(command)
  local menu = self
  local direction = (command == "left" and -1) or (command == "right" and 1)
  local did_scroll = false
  new_index = menu.cursor_index + direction
  if new_index >= 1 and new_index <= #menu.categories then
    menu.cursor_index = new_index
    did_scroll = true
    if menu.cursor_sound then sol.audio.play_sound(menu.cursor_sound) end
  end
  menu.currently_scrolling = command
  menu:update()
  return did_scroll
end


menu_prototype:register_event("on_command_pressed", function(self, command)
  local menu = self
  local handled = false
  if command == "left" or (command == "right") then
    handled = menu:scroll(command)
  elseif command == "down" then
    menu.cursor_line:set_opacity(0)
    menu:update()
    handled = true
  end
  return handled
end)


function menu_prototype:start_submenu(context, submenu)
  --Starts a submenu, and closes the current menu. The submenu can use submenu:quit_to_parent() to re-open the parent menu.
  assert(context, "Cannot start submenu, bad argument #1 to 'start_submenu', context needed (either map, game, sol.main, or table)")
  assert(submenu, "Bad argument #2 to 'start_submenu', submenu needs to be provided and you just provided the context")
  assert(submenu.set_parent_menu, "Cannot start submenu. Provided submenu does not have a 'set_parent_menu(parent_context, parent_menu) function")
  local menu = self
  submenu:set_parent_menu(context, menu)
  sol.menu.start(context, submenu, true)
  sol.menu.stop(menu)
end


function menu_prototype:set_parent_menu(parent_context, parent_menu)
  local menu = self
  assert(type(parent_menu) == "table", "Bad argument #1 to 'set_parent_menu' (menu expected)")
  assert(parent_context, "Bad argument #2 to 'set_parent_menu' (menu context expected)")
  menu.parent_menu = parent_menu
  menu.parent_context = parent_context
end


function menu_prototype:quit_to_parent()
  local menu = self
  assert(menu.parent_menu and menu.parent_context, "Cannot quit to parent menu, requires first calling submenu:set_parent_menu(parent_menu, parent_menu_context)")
  sol.menu.stop(menu)
  sol.menu.start(menu.parent_context, menu.parent_menu)
end


function menu_prototype:set_index(new_index)
  menu.cursor_index = new_index
  menu:update()
end


menu_prototype:register_event("on_draw", function(self, screen)
  local menu = self
  menu.background_surface:draw(screen, menu.origin_x + menu.background_offset.x, menu.origin_y + menu.background_offset.y)
  menu.categories_surface:draw(screen, menu.origin_x, menu.origin_y)
  menu.sub_l_icon:draw(screen, menu.origin_x - 16, menu.origin_y + 13)
  menu.sub_r_icon:draw(screen, menu.origin_x + menu.width + 16, menu.origin_y + 13)

  --This is a bit hacky, but
  if menu.active_submenu.unfocused and menu.cursor_line:get_opacity() == 0 then
    menu.cursor_line:set_opacity(255)
    menu:update()
  end
end)


--Avoid analog stick wildly jumping
if sol.main.old_controls_version or ( tonumber(sol.main.get_solarus_version():match("(%d+.%d+)")) < 1.7 ) then
  function menu_prototype:on_joypad_axis_moved(axis,state)
    local menu = self
    menu.joy_avoid_repeat = menu.joy_avoid_repeat or {-2, -2}
    local handled = menu.joy_avoid_repeat[axis % 2] == state
    menu.joy_avoid_repeat[axis % 2] = state

    if handled then return handled end
  end
end


function factory.create(config)
    local menu = {}
    menu.categories = config.categories
    menu.width = config.size and config.size.width or 416
    menu.height = config.size and config.size.height or 240
    menu.origin_x = config.origin and config.origin.x or 0
    menu.origin_y = config.origin and config.origin.y or 0
    menu.category_offset = config.category_offset or {x = 0, y = 0}
    menu.font = config.font or default_settings.font
    menu.font_size = config.font_size or default_settings.font_size
    menu.font_color = config.font_color or default_settings.font_color
    menu.category_width = config.category_width or (menu.width / #menu.categories)
    menu.category_padding = config.category_padding or 8
    menu.category_height = config.category_width or 16
    menu.background_color = config.background_color or {0,0,0,0}
    menu.background_png = config.background_png
    menu.background_9slice_config = config.background_9slice_config
    menu.background_offset = config.background_offset or {x = 0, y = 0}
    menu.cursor_sound = config.cursor_sound
    menu.cursor_width = config.cursor_width or (menu.width / #menu.categories - 16)

    setmetatable(menu, menu_metatable)

    menu_features_manager.apply_menu_features(menu)
    menu_features_manager.apply_category_menu_features(menu)

    return menu
end

return factory