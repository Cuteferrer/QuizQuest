local menu = {}

menu.x, menu.y = 0, 0

local background = sol.modules.get_object("trilmenu_nineslice").get_surface({
  width = 160, height = 32,
  source_png = "menus/panel_blocks/small.png", tile_width = 8,
})
local draw_surface = sol.surface.create(background:get_size())
local text_surface = sol.text_surface.create{
  font = "enter_command",
  font_size = 16,
}

function menu:set_result(result)
  draw_surface:clear()
  text_surface:set_text(result)
  text_surface:draw(draw_surface, 32, 16)

  local sprite = sol.sprite.create("entities/items")
  sprite:set_animation("meals/" .. result)
  sprite:draw(draw_surface, 16, 21)

end

function menu:on_command_pressed()
  sol.menu.stop(self)
  return true
end

function menu:on_draw(dst)
  background:draw(dst, menu.x, menu.y)
  draw_surface:draw(dst, menu.x, menu.y)
end


return menu
