--[[
Config describing which submenus should show on the pause screen
Submenus require a name field, which should correspond to a string at "menu.pause.submenu_name"
--]]

return {
  submenus = {
    {
      name = "tools",
      menu = require("scripts/menus/pause/inventory/tools_inventory")
    },
    {
      name = "weapons",
      menu = require("scripts/menus/pause/inventory/weapons_inventory")
    },
    {
      name = "meals",
      menu = require("scripts/menus/pause/inventory/meals_inventory")
    },
    {
      name = "system",
      menu = require("scripts/menus/pause/system_menu"),
    },
  },

}
