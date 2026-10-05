local language_manager = sol.modules.get_object("language_manager")
local bg_9slicer = sol.modules.get_object("trilmenu_nineslice")


local menu = { x = 0, y = 0}
local config
local font, font_size, vert_spacing = language_manager:get_dialog_font()


local function get_bg()
  if config.bg_type == "9slice" then
    return bg_9slicer.get_surface{
      width = config.width, height = config.height,
      source_png = config.bg_source,
      tile_width = config.slice_width, tile_height = config.slice_height,
    }
  else
    return sol.surface.create(config.bg_source)
  end
end


function menu:set_config(new_config)
  config = new_config
end


function menu:set_name(display_name)
  menu.draw_surface:clear()
  menu.text_surface:set_color_modulation(config.font_color)
  menu.text_surface:set_text(display_name)
  menu.bg_surface:draw(menu.draw_surface, 0, 0)
  menu.text_surface:draw(menu.draw_surface, config.text_indent, config.height / 2)
end

function menu:on_started()
  assert(config, "Error: 'name_box_menu:set_config()' must be called before starting menu")
  --Reset font in case language has changed:
  font, font_size, vert_spacing = language_manager:get_dialog_font()
  --Create surfaces
  menu.draw_surface = sol.surface.create()
  menu.bg_surface = get_bg()
  menu.text_surface = sol.text_surface.create({
    font = font,
    font_size = font_size,
  })
end


function menu:opening_animation()
  local slide_offset = 64
  local angle = math.pi / 2
  menu.draw_surface:fade_in(5)
  local dx = math.floor(math.cos(angle) * slide_offset) * -1
  local dy = math.floor(math.sin(angle) * slide_offset)
  menu.draw_surface:set_xy(dx, dy)
  local m = sol.movement.create("straight")
  m:set_speed(480)
  m:set_max_distance(slide_offset)
  m:set_angle(angle)
  m:start(menu.draw_surface)
end


function menu:on_draw(dst)
  menu.draw_surface:draw(dst, menu.x + config.offset_x, menu.y + config.offset_y)
end


return menu
