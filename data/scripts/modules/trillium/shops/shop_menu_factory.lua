local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()
require("scripts/modules/trillium_config/game_data/shop_inventories") --set up config for shop inventories so they can all be edited in one place
local ui_config = require("scripts/modules/trillium_config/ui/shop_menu_config") --config about how the menu is laid out, etc.
local money_hud = require("scripts/modules/trillium/shops/money_hud") --specific HUD for money in shops, since HUD is likely disabled

local manager = {}

local function filter_inventory(inventory)
  local allowed_objects = {}
  for i, item in ipairs(inventory) do
    local item_id = item.id
    local name_key = string.gsub("items." .. item_id, "/", ".")
    local object = {
      name = item_id,
      itype = item.itype,
      price = item.price,
      variant = item.variant or 1,
      quantity = item.quantity,
      sprite = "_item",
      sprite_offset = {x=16, y=19},
      display_function = function(object)
        if not object.quantity then return true
        else return object.quantity > 0 end
      end,
      description_name_string = name_key,
      description_sprite = "entities/items",
      description_sprite_animation = item_id,
      text_offset = { x = 5, y = 24},
      text_config = {
        font = font,
      },
      text_function = function()
        if ui_config.show_price_on_icon then
          local cur_sym = sol.language.get_string(ui_config.currency_symbol)
          if ui_config.currency_symbol_position == "before" then
            return cur_sym .. item.price
          else
            return item.price .. cur_sym
          end
        else
          return ""
        end
      end,
    }
    table.insert(allowed_objects, object)
  end
  return allowed_objects
end

local function update_object_in_inventory(object, inventory)
  for _, item in pairs(inventory) do
    if object.name == item.id then
      item.quantity = object.quantity
    end
  end
  return inventory
end



function manager.get_shop_menu(shop_id, inventory)
  assert(type(inventory) == "table", "bad argument #2 to 'open_shop', type should be table")
  local shop_savegame_id = "shop_inventory_" .. shop_id
  local game = sol.main.get_game()

  --Aux menus:-----
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


  --Note: this requires savegame table serialization.
  local saved_inventory = game:get_table_value(shop_savegame_id)
  if saved_inventory then
    inventory = saved_inventory
  end

  --Filter out items that have a 0 quantity
  local allowed_objects = filter_inventory(inventory)

  --Set config
  local config = ui_config.base_grid_config
  config.allowed_objects = allowed_objects
  config.aux_menus = {
    description_box, command_legend, shop_decoration, money_hud
  }
  --Create the menu
  local menu = sol.modules.get_object("trilmenu_grid").create(config)

  --Suspend the game when the menu is open
  menu:register_event("on_started", function()
    sol.main.get_game():set_suspended(true)
  end)
  menu:register_event("on_finished", function()
    sol.main.get_game():set_suspended(false)
  end)

  --Hide HUD when open:
  menu:hide_hud_when_open()


  --Callback for purchasing an item
  local function purchase(object)
    local id, price, variant = object.name, object.price, object.variant
    local item = game:get_item(id)
    --give the item, call relevant callbacks:
    if item:get_savegame_variable() then --only give items that have a possession state
      item:set_variant(variant)
    end
    if item.on_obtaining then item:on_obtaining(variant) end
    if item.on_obtained then item:on_obtained(variant) end
    --manually show the item panel:
    item:show_popup(variant)
    --Remove quantity from merchant's inventory:
    if object.quantity then object.quantity = object.quantity - 1 end
    --Update the metchant's inventory table in savegame:
    inventory = update_object_in_inventory(object, inventory)
    game:set_table_value(shop_savegame_id, inventory)
    --Update objects currently displayed on menu
    allowed_objects = filter_inventory(inventory)
    menu:update_objects()
    game:remove_money(price)
    sol.audio.play_sound("money_spend")

    --Update money aux menu:
    menu:notify_aux_menus()
  end


  --Handle choosing an item:
  menu:register_event("on_command_pressed", function(self, command)
    local handled = false
    if command == "confirm" then
      local object = menu:get_selected_object()
      local id, price, variant = object.name, object.price, object.variant

      if game:get_money() < price then
        game:start_dialog("menus.shop.insufficient_funds")
      else
        game:start_dialog(
          ui_config.purchase_confirmation_dialog,
          { v1 = sol.language.get_string("items." .. id:gsub("/", ".")),
            v2 = price,
          },
          function(answer)
            if answer == 1 then purchase(object) end
          end
        )
      end
      local handled = true
    elseif command == "cancel" or command == "item_1" or command == "item_2" or command == "pause" then
      sol.menu.stop(menu)
      handled = true
    end
    return handled
  end)

  return menu
end

return manager
