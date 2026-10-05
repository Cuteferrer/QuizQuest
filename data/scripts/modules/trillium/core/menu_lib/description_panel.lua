--A description panel for a grid menu. Can display text and a sprite
-- Licensed under MIT. Authored by Max Mraz.

local multi_events = sol.modules.get_object("multi_events")
local default_settings = require("scripts/modules/trillium/core/menu_lib/default_settings")

local factory = {}

local menu_prototype = {}
multi_events:enable(menu_prototype)

local menu_metatable = {__index = menu_prototype}


menu_prototype:register_event("on_started", function(self)
  local menu = self

  menu.background_surface = sol.surface.create(menu.width, menu.height)
  menu.background_surface:fill_color(menu.background_color)
  if menu.background_png then
    menu.background_surface = sol.surface.create(menu.background_png)
  end

  menu.description_surface = sol.surface.create(menu.width, menu.height)

  menu.sprite_surface = sol.surface.create(menu.sprite_surface_width, menu.sprite_surface_height)
  menu.text_surface = sol.surface.create(menu.text_surface_width, menu.text_surface_height)
  menu.name_surface = sol.text_surface.create{ font = menu.font, font_size = menu.font_size, color = menu.font_color}
  menu.base_surface = sol.surface.create() --surface to contain all other surfaces, to manage movement or opacity on

  menu:update()
end)


function menu_prototype:notify(grid_menu)
  local menu = self
  local object = grid_menu:get_selected_object()
  menu.description_sprite = nil
  menu.description_dialog = nil
  if object and object.description_sprite then
    menu.description_sprite = sol.sprite.create(object.description_sprite)
    if object.description_sprite_animation then menu.description_sprite:set_animation(object.description_sprite_animation) end
  end
  if object and object.description_dialog then
    menu:set_description_dialog(object.description_dialog)
  else
    menu:clear_description_dialog()
  end
  if object and object.description_name_string then
    menu:set_description_name(object.description_name_string)
  else
    menu.name_surface:set_text("")
  end
  menu:update()
end


function menu_prototype:set_description_dialog(dialog_id)
  local menu = self
  menu.text_surface:clear()
  local dialog_string = sol.language.get_dialog(dialog_id)
  if dialog_string == nil then
    return
  else
    dialog_string = dialog_string.text
  end
  lines = {}
  for s in dialog_string:gmatch("[^\r\n]+") do
      table.insert(lines, s)
  end
  local _, line_height = sol.text_surface.get_predicted_size(menu.font, menu.font_size, "W")
  for i = 1, #lines do
    local txt = sol.text_surface.create{
      font = menu.font, font_size = menu.font_size, color = menu.font_color,
      vertical_alignment = "top",
      text = lines[i]
    }
    txt:draw(menu.text_surface, menu.text_margin, line_height * (i - 1))
  end
end


function menu_prototype:set_description_name(string_id)
  local menu = self
  menu.name_surface:set_text("")
  local string = sol.language.get_string(string_id)
  if string then
    menu.name_surface:set_text_key(string_id)
  else
    print("WARNING, description menu cannot find item's name string. String ID:", string_id)
  end
end


function menu_prototype:clear_description_dialog()
  local menu = self
  menu.text_surface:clear()
end


function menu_prototype:update()
  local menu = self
  menu.sprite_surface:clear()
  menu.description_surface:clear()
  if menu.description_sprite then
    --Centered:
    --menu.description_sprite:draw(menu.sprite_surface,  menu.sprite_surface_width / 2, menu.sprite_surface_height - 3)
    --Left:
    menu.description_sprite:draw(menu.sprite_surface,  32, menu.sprite_surface_height - 3)
  end
  menu.sprite_surface:draw(menu.description_surface, 0, menu.sprite_surface_y_offset)
  menu.text_surface:draw(menu.description_surface, 0, menu.text_surface_y_offset)
  menu.name_surface:draw(menu.description_surface, menu.name_offset_x, menu.name_offset_y)
end


function menu_prototype:fade_in(speed)
  speed = speed or 5
  self.base_surface:fade_in(speed)
end


menu_prototype:register_event("on_draw", function(self, screen)
  self.background_surface:draw(self.base_surface, self.origin_x, self.origin_y)
  self.description_surface:draw(self.base_surface, self.origin_x, self.origin_y)
  self.base_surface:draw(screen, 0, 0)
end)


function factory.create(config)
    local menu = {}
    menu.width = config.panel_size and config.panel_size.width or 192
    menu.height = config.panel_size and config.panel_size.height or 200
    menu.origin_x = config.origin and config.origin.x or 30
    menu.origin_y = config.origin and config.origin.y or 40
    menu.name_offset_x, menu.name_offset_y = config.name_surface_offset and config.name_surface_offset.x or 0, config.name_surface_offset and config.name_surface_offset.y or 0
    menu.sprite_surface_width = config.sprite_surface_size and config.sprite_surface_size.width or 192
    menu.sprite_surface_height = config.sprite_surface_size and config.sprite_surface_size.height or 48
    menu.text_surface_width = config.text_surface_size and config.text_surface_size.width or 192
    menu.text_surface_height = config.text_surface_size and config.text_surface_size.height or 56
    menu.sprite_surface_y_offset = config.sprite_surface_y_offset or 0
    menu.text_surface_y_offset = config.text_surface_y_offset or 56
    menu.font = config.font or default_settings.font
    menu.font_size = config.font_size or default_settings.font_size
    menu.font_color = config.font_color or default_settings.font_color
    menu.text_margin = config.text_margin or 4
    menu.background_color = config.background_color or {0,0,0,0}
    menu.background_png = config.background_png

    setmetatable(menu, menu_metatable)

    return menu
end

return factory