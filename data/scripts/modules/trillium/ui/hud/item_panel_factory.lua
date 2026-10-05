
local factory = {}

function factory.new()
  local menu = {x=0, y=0}

  local text_surface = sol.text_surface.create()
  local quantity_surface = sol.text_surface.create()
  local icon_sprite = sol.sprite.create("entities/items")
  local panel_surface = sol.surface.load("sprites/hud/item_panel.png")
  local draw_surface = sol.surface.create(panel_surface:get_size())

  function menu:set_item(item_id, variant)
    variant = variant or 1
    icon_sprite:set_animation(item_id)
    icon_sprite:set_direction(variant - 1)
    panel_surface:draw(draw_surface, 0, 0)
    icon_sprite:draw(draw_surface, 16, 21)
  end

  function menu:fade_out(callback)
    draw_surface:fade_out()
    sol.timer.start(menu, 1000, function()
      if callback then callback() end
    end)
  end

  function menu:on_draw(dst)
    draw_surface:draw(dst, menu.x, menu.y)
  end

  return menu
end

return factory
