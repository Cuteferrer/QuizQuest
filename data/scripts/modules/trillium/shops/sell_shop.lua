local default_inventory = require("scripts/modules/trillium_config/game_data/shop_sell_prices")
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()
local ui_config = require("scripts/modules/trillium_config/ui/shop_menu_config") --config about how the menu is laid out, etc.
local money_hud = require("scripts/modules/trillium/shops/money_hud") --specific HUD for money in shops, since HUD is likely disabled

local function process_inventory_list(inventory)
  inventory = inventory or default_inventory
  local allowed_objects = {}
  for i, item in ipairs(inventory) do
    local item_id = item.id
    local name_key = string.gsub("items." .. item_id, "/", ".")
    local object = {
      name = item_id,
      price = item.price,
      sprite = "_item",
      sprite_offset = {x = 16, y = 21},
      --display_function = "_item",
      display_function = function()
        return sol.main.get_game():get_item(item_id):has_amount(1)
      end,
      description_name_string = name_key,
      description_sprite = "entities/items",
      description_sprite_animation = item_id,
      text_offset = { x = 5, y = 24},
      text_function = function()
        return sol.main.get_game():get_item(item_id):get_amount() or ""
      end,
    }
    table.insert(allowed_objects, object)
  end
  return allowed_objects
end


--Aux menus:-----
--Name box
--I don't remember what name box is for...
-- local name_box = sol.modules.get_object("trilmenu_namebox").create()
-- name_box.x, name_box.y = ui_config.name_box_x, ui_config.name_box_y
--Description box
local description_box = require("scripts/modules/trillium/shops/item_description_box")
description_box.x, description_box.y = ui_config.description_box_x, ui_config.description_box_y
--Command Legend
local command_legend = sol.modules.get_object("trilmenu_component_command_legend").new({
  commands = {
    { command = "cancel",  action = "menu.actions.exit"},
  },
  x = ui_config.command_legend_x, y = ui_config.command_legend_y,
})
--Decoration above menu:
local shop_decoration = {}
if ui_config.menu_decoration_png then
  local decoration_texture = sol.surface.load(ui_config.menu_decoration_png)
  function shop_decoration:on_draw(dst)
    decoration_texture:draw(dst, ui_config.decoration_x, ui_config.decoration_y)
  end
end
function shop_decoration:notify() end
--Money HUD:
money_hud.x, money_hud.y = ui_config.money_hud_x, ui_config.money_hud_y


--Set config
local config = ui_config.base_grid_config
config.allowed_objects = process_inventory_list()
config.aux_menus = {
  description_box, command_legend, shop_decoration, money_hud
}
--Create the menu
local menu = sol.modules.get_object("trilmenu_grid").create(config)


--Suspend the game when the menu is open
menu:register_event("on_started", function()
  local game = sol.main.get_game()
  game:set_suspended(true)
  game.force_money_display = true
end)
menu:register_event("on_finished", function()
  local game = sol.main.get_game()
  game:set_suspended(false)
  game.force_money_display = false
end)

--Hide HUD when open:
menu:hide_hud_when_open()


--allow to purchase different items
function menu:set_inventory(inventory)
  menu.allowed_objects = process_inventory_list(inventory)
end


function menu:sell_item(object)
  local game = sol.main.get_game()
  local item = game:get_item(object.name)
  if item:get_amount() > 0 then
    sol.audio.play_sound("money_spend")
    game:add_money(object.price)
    item:remove_amount(1)
    menu:update_objects()
  end
end


menu:register_event("on_command_pressed", function(self, command)
  local handled = false
  if command == "confirm" then
    local game = sol.main.get_game()
    local object = menu:get_selected_object()
    if not object then return end
    local id, price = object.name, object.price
    game:start_dialog(
      ui_config.sell_confirmation_dialog,
      { v1 = sol.language.get_string("items." .. id:gsub("/", ".")),
        v2 = price,
      },
      function(answer)
        if answer == 1 then menu:sell_item(object) end
      end
    )
    handled = true
  elseif command == "cancel" or command == "item_1" or command == "item_2" or command == "pause" then
    sol.menu.stop(menu)
    handled = true
  end
  return handled
end)

return menu
