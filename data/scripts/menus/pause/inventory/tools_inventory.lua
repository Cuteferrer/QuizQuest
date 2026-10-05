--[[
By Max Mraz, licensed MIT

Tools inventory: equip the typical 2D Zelda items to item_1 and item_2 slots
--]]

local possible_objects = require("scripts/menus/pause/inventory/tools_list")
local config_manager = require("scripts/menus/configs/grid_config_manager")
local allowed_objects = require("scripts/menus/pause/inventory/grid_objects_builder").build_equipment_item_objects(possible_objects)
local command_legend_defaults = require("scripts/menus/pause/inventory/command_legend_defaults").new({
  { command = "item_1",  action = "menu.actions.equip_1"},
  { command = "item_2",  action = "menu.actions.equip_2"},
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
  if command == "item_1" and sel_ob then
    menu:equip_item(1, sel_ob.name)
    handled = true
  elseif command == "item_2" and sel_ob then
    menu:equip_item(2, sel_ob.name)
    handled = true
  end
  return handled
end)


function menu:equip_item(slot, item_id)
  local game = sol.main.get_game()
  local item = game:get_item(item_id)
  game:set_item_assigned(slot, item)
  sol.sound.create("charm_equip"):play()
  menu:update_objects()
end


return menu
