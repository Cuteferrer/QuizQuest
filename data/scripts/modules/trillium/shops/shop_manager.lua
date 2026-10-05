--[[
Shops / Merchants menus
Created by Max Mraz, licensed MIT

Usage:
game:open_shop(shop_id, inventory)
Example inventory table:
{
  {id = "consumables/remedial_mushroom", price = 10,}, --item_id and price and required
  {id = "charms/flamestep", price = 200, quantity = 1,}, --quantity is optional, otherwise there will be an infinite quantity in the shop
  {id = "inventory/boomerang", price = 500, variant = 2, quantity = 1,}, --variant is another optional field
}

game:open_sell_shop(inventory)
- Inventory is optional, there's a default one
- This is for selling your inventory to a merchant to make money
--]]

local manager = {}
local game_meta = sol.main.get_metatable"game"

local buy_shop_factory = require("scripts/modules/trillium/shops/shop_menu_factory")
local sell_menu = require"scripts/modules/trillium/shops/sell_shop"



function game_meta:open_shop(shop_id, inventory)
  assert(type(shop_id) == "string", "bad argument #1 to 'open_shop', type should be string")
  assert(type(inventory) == "table", "bad argument #2 to 'open_shop', type should be table")
  local game = self
  local shop_menu = buy_shop_factory.get_shop_menu(shop_id, inventory)
  sol.menu.start(game, shop_menu)
  return shop_menu
end


function game_meta:add_to_shop(shop_id, old_inventory, new_inventory)
  assert(type(shop_id) == "string", "bad argument #1 to 'add_to_shop', type should be string")
  assert(type(old_inventory) == "table", "bad argument #2 to 'add_to_shop', type should be table for old shop inventory")
  assert(type(new_inventory) == "table", "bad argument #3 to 'add_to_shop', type should be table for updated shop inventory")
  local game = self
  local shop_savegame_id = "shop_inventory_" .. shop_id
  local saved_inventory = game:get_table_value(shop_savegame_id) or old_inventory
  local updated_inventory = {}
  for i, v in ipairs(saved_inventory) do
    updated_inventory[#updated_inventory + 1] = v
  end
  for i, v in pairs(new_inventory) do
    updated_inventory[#updated_inventory + 1] = v
  end
  game:set_table_value(shop_savegame_id, updated_inventory)
end


function game_meta:remove_from_shop(shop_id, item_id)

end


function game_meta:open_sell_shop(inventory)
  sell_menu:set_inventory(inventory)
  sol.menu.start(self, sell_menu)
end



return manager