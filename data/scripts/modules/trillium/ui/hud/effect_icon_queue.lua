local font, font_size = sol.modules.get_object("language_manager"):get_dialog_font()

local builder = {}

function builder:new(game, config)
  local menu = {}
  menu.x, menu.y = config.x or 208, config.y or 155
  menu.active_icons = {}

  local icon_sprite = sol.sprite.create("hud/effect_icons")
  local icons_surface = sol.surface.create(200, 16)

  function menu:is_icon_active(icon_id)
    local is_active = false
    for _, icon in ipairs(menu.active_icons) do
      if icon == icon_id then
        is_active = true
        break
      end
    end
    return is_active
  end


  function menu:add_icon(icon_id)
    assert(icon_sprite:has_animation(icon_id), "Cannot show effect icon: '" .. icon_id .. "' - no corresponding animation found in 'hud/effect_icons'")
    if menu:is_icon_active(icon_id) then return end
    menu.active_icons[#menu.active_icons+1] = icon_id
  end


  function menu:remove_icon(icon_id)
    for i, icon in ipairs(menu.active_icons) do
      if icon == icon_id then
        table.remove(menu.active_icons, i)
      end
    end
  end


  --Add function to game:
  function game:add_hud_effect_icon(icon_id)
    menu:add_icon(icon_id)
  end

  function game:remove_hud_effect_icon(icon_id)
    menu:remove_icon(icon_id)
  end



  function menu:on_started()
    sol.timer.start(menu, 100, function()
      menu:draw_icons()
      return true
    end)
  end

  function menu:draw_icons()
    icons_surface:clear()
    for i, icon in ipairs(menu.active_icons) do
      icon_sprite:set_animation(icon)
      icon_sprite:draw(icons_surface, (i) * 12, 4)
    end
  end


  function menu:on_draw(dst)
    icons_surface:draw(dst, menu.x, menu.y)
  end


  return menu

end


return builder
