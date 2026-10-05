--[[
By Max Mraz, licensed MIT

Determines what happens when you pick up an item,
whether from a pickable, from a chest, or other
--]]

local item_meta = sol.main.get_metatable("item")

--Show item popup modal:
local popup_menu = sol.modules.get_object("trilmenu_component_item_popup")
function item_meta:show_popup(variant)
  local item = self
  local game = sol.main.get_game()
  popup_menu:set_item(item:get_name(), variant)
  if sol.menu.is_started(popup_menu) and popup_menu.item_id == item:get_name() then
    --This item has already shown its popup menu
    return
  elseif sol.menu.is_started(popup_menu) then
    sol.menu.stop(popup_menu)
  end
  sol.menu.start(game, popup_menu)
end

function item_meta.on_obtaining(item, variant, savegame_var)
  local game = item:get_game()
  local item_id = item:get_name()

  --Decide what popup to show:
  if item:has_amount() and game.show_item_hud_panel then
    game:show_item_hud_panel(item_id, variant)
  else
    item:show_popup()
  end
end

