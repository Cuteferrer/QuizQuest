--[[
Written by Max Mraz, licensed MIT

Use this script to apply other features to all grid menus and category selection menus
These functions will be called just before the menu is returned, after it's been set up
--]]

local manager = {}


function manager.apply_grid_menu_features(menu)

  function menu:hide_hud_when_open()
    menu:register_event("on_started", function()
      local game = sol.main.get_game()
      --Hide HUD when started:
      menu.hud_hidden = true
      game:set_hud_enabled(false)
    end)
    menu:register_event("on_finished", function()
      local game = sol.main.get_game()
      --Show HUD if this menu hid it:
      if menu.hud_hidden then
        game:set_hud_enabled(true)
      end
      menu.hud_hidden = false
    end)
  end

  function menu:fade_in(speed)
    speed = speed or 1
    menu.base_surface:fade_in(speed)
    for i, aux_menu in pairs(menu.aux_menus or {}) do
      if aux_menu.fade_in then aux_menu:fade_in(menu.fade_in_speed) end
    end
  end

end

function manager.apply_category_menu_features(menu)

end


function manager.apply_menu_features(menu)

end



return manager

