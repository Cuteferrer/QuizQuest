--[[
By Max Mraz, licensed MIT

Weapons inventory: equip solforge weapons to the attack button
--]]

local possible_objects = require("scripts/menus/pause/inventory/weapons_list")
local config_manager = require("scripts/menus/configs/grid_config_manager")
local allowed_objects = require("scripts/menus/pause/inventory/grid_objects_builder").build_equipment_item_objects(possible_objects)
local command_legend_defaults = require("scripts/menus/pause/inventory/command_legend_defaults").new({
  { command = "confirm",  action = "menu.actions.equip"},
})
local command_legend_menu = sol.modules.get_object("trilmenu_component_command_legend").new(command_legend_defaults)


local config = config_manager.get_standard_config({
  allowed_objects = allowed_objects,
  aux_menus = { command_legend_menu }
})

local menu = sol.modules.get_object("trilmenu_grid").create(config)

menu:register_event("on_command_pressed", function(menu, command, controls_ob)
  local handled = false
  local sel_ob = menu:get_selected_object()
  if command == "confirm" and sel_ob then
    menu:equip_item(sel_ob.name)
  end
  return handled
end)


function menu:equip_item(item_id)
  local game = sol.main.get_game()
  game:set_value("equipped_weapon", item_id)
  sol.sound.create("charm_equip"):play()
end


return menu
