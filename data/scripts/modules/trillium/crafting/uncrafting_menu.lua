--[[
Menu for taking your crafted items and breaking them down into the components used to create them
--]]

local language_manager = sol.modules.get_object("language_manager")
local font, font_size = language_manager:get_menu_font()
local recipes_list = require"scripts/modules/trillium_config/game_data/crafting_recipes"

local origin_x, origin_y = 64, 24
local cell_width = 32
--local cell_width = 176


local command_legend = sol.modules.get_object("trilmenu_component_command_legend").new({
  commands = {
    { command = "confirm", action = "menu.actions.confirm" },
    { command = "item_1", action = "menu.actions.describe" },
    { command = "cancel",  action = "menu.actions.exit"},
  },
  x = 48, y = 220,
})


--Config:
local config = require("scripts/menus/inventory/grid_config").get_config{
  origin = {x = 96, y = 48},
  grid_size = {columns = 5, rows = 4},
  background_png = nil,
  background_9slice_config = {
    width = 192, height = 160
  },
  background_offset = {x = -6, y = -6},
  aux_menus = { command_legend },
}


local allowed_objects = {}
for i, recipe in ipairs(recipes_list) do
  local ob = {}
  ob.name = recipe.item
  ob.sprite = "_item"
  ob.sprite_offset = {x = 16, y = 18}
  ob.display_function = "_item"
  ob.recipe_table = recipe
  allowed_objects[i] = ob
end
config.allowed_objects = allowed_objects


local menu = sol.modules.get_object("trilmenu_grid").create(config)



--Handle Input
menu:register_event("on_command_pressed", function(self, command)
  local game = sol.main.get_game()
  local handled = false
  if command == "confirm" then
    menu:process_selection()
    handled = true

  elseif command == "item_1" then
    local ob = menu:get_selected_object()
    local description_id = "item_descriptions." .. ob.name:gsub("/", ".")
    game:start_dialog(description_id)

  elseif command == "cancel" then
    sol.menu.stop(menu)
    handled = true
  end
  return handled
end)


function menu:process_selection()
  local game = sol.main.get_game()
  local ob = menu:get_selected_object()
  if not ob then return end
  local recipe = ob.recipe_table
  local item = game:get_item(recipe.item)
  local item_id = item:get_name()

  game:start_dialog("menus.crafting.confirm_disassemble", function(answer)
    if answer == 1 then
      item:set_variant(0)
      for _, list_item in ipairs(recipe) do
        local ingredient, quantity = list_item.ingredient, list_item.quantity
        local ing_item = game:get_item("materials/crafting/" .. ingredient)
        ing_item:add_amount(quantity)
      end
      --unequip if equipped:
      for i = 1, 2 do
        if (game:get_item_assigned(i) == item_id) then
          game:set_item_assigned(i)
        end
      end
      if game.is_item_in_quickswap_slot then
        local category, slot = game:is_item_in_quickswap_slot(item_id)
        if category then
          game:set_quickswap_item(category, slot, nil)
          --note: setting quickswap items will automatically unequip if active
        end
      end
      menu:update_objects()
    end
  end)
end


return menu

