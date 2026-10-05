--[[
Component to use as an aux menu
Shows the "name" field of any object selected by a grid menu

Usage:
sol.modules.get_object("trilmenu_namebox").create(config)

Config:

--]]

local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()

local manager = {}

function manager.create(config)
  config = config or {}
  local menu = {x = 0, y = 0}
  local width, height = config.width or 208, config.height or 24

  local menu_surface = sol.surface.create()

  local bg_surface = sol.modules.get_object("trilmenu_nineslice").get_surface{
    width = width, height = height,
    source_png = "menus/panel_blocks/small.png",
    tile_width = 8, tile_height = 8,
  }

  local name_surface = sol.text_surface.create{
    font = font,
    font_size = font_size,
    horizontal_alignment = "center",
  }


  function menu:notify(parent)
    local sel_ob = parent:get_selected_object()
    if sel_ob then
      local name = sel_ob.name:gsub("/", ".")
      --for example: "inventory/healing_flask"
      name_surface:set_text(sol.language.get_string("items." .. name))
    else
      name_surface:set_text("")
    end
    menu:update()
  end


  function menu:update()
    menu_surface:clear()
    bg_surface:draw(menu_surface)
    name_surface:draw(menu_surface, width / 2, 12)
  end


  function menu:on_draw(dst)
    menu_surface:draw(dst, menu.x, menu.y)
  end


  return menu
end


return manager
