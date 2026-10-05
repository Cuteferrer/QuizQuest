local menu = {}
menu.x, menu.y = 0, 0

local background = sol.modules.get_object("trilmenu_nineslice").get_surface({
  width = 192, height = 16,
  source_png = "menus/panel_blocks/small.png", tile_width = 8,
})
local name_surface = sol.text_surface.create{
  font = "enter_command",
  font_size = 16,
}
local sprite_surface = sol.surface.create(16, 16)

function menu:notify(grid_menu)
  sprite_surface:clear()
  if grid_menu:get_selected_object() then
    local object = grid_menu:get_selected_object()
    name_surface:set_text(object.food_name)
    local sprite = sol.sprite.create("entities/items")
    sprite:set_animation(object.name)
    --sprite:draw(sprite_surface, 8, 13)
  end
end


function menu:on_draw(dst)
  background:draw(dst, menu.x, menu.y)
  name_surface:draw(dst, menu.x + 24, menu.y + 8)
  sprite_surface:draw(dst, menu.x + 8, menu.y)
end

return menu
