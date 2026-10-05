local language_manager = sol.modules.get_object("language_manager")
local font, font_size = language_manager:get_menu_font()
local recipes_list = require"scripts/modules/trillium_config/game_data/crafting_recipes"
local recipe_panel_menu = require"scripts/modules/trillium/crafting/recipe_panel"


local origin_x, origin_y = 64, 24
local cell_width = 32
--local cell_width = 176

--Config:
local config = {
  origin = {x=origin_x, y=origin_y},
  grid_size = {columns = 3, rows = 4},
  cell_size = {width = cell_width, height = 32},
  cell_spacing = 4,
  --cell_png = "menus/inventory/circle_cell.png",
  edge_spacing = 8,
  cursor_style = "menus/arrow",
  cursor_offset = {x=-2, y=8},
  cursor_sound = "cursor",
  background_9slice_config = {
    width = 128, height = 160
  },
  background_offset = {x = -4, y = 0},
  --background_color = {30,30,30,200},
  --cell_color = {100,100,100,200},
}


local allowed_objects = {}
for i, recipe in ipairs(recipes_list) do
  local ob = {}
  if recipe.line_break then
    ob.line_break = true
    ob.display_function = function() return true end
  else
    ob.name = recipe.item
    ob.sprite = "_item"
    ob.sprite_offset = {x = 16, y = 18}
    ob.display_function = function()
      local game = sol.main.get_game()
      local has_item = game:has_item(recipe.item)
      local unlocked = (recipe.unlock_value == nil) or game:get_value(recipe.unlock_value)
      return unlocked and not has_item
    end
    ob.recipe_table = recipe
  end
  allowed_objects[i] = ob
end
config.allowed_objects = allowed_objects


--Set up aux menus:
local selection_panel_config = {
  origin = {x = origin_x + 132, y = origin_y},
  background_9slice = "menus/panel_blocks/small.png",
  --cell_color = {100,100,100,200},
}
local recipe_panel = recipe_panel_menu.create(selection_panel_config)
local command_legend = sol.modules.get_object("trilmenu_component_command_legend").new({
  commands = {
    { command = "confirm", action = "menu.actions.craft" },
    { command = "item_1", action = "menu.actions.describe" },
    { command = "cancel",  action = "menu.actions.exit"},
  },
  x = 48, y = 220,
})
config.aux_menus = { recipe_panel, command_legend, }


local menu = sol.modules.get_object("trilmenu_grid").create(config)


--Suspend game when menu starts / stops
menu:register_event("on_started", function()
  local game = sol.main.get_game()
  game:set_suspended(true)
end)

menu:register_event("on_finished", function()
  local game = sol.main.get_game()
  game:set_suspended(false)
end)


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
  local result_item = game:get_item(ob.name)

  local can_craft = true
  for i, list_item in ipairs(recipe) do
    local ingredient, quantity = list_item.ingredient, list_item.quantity
    ingredient = "materials/crafting/" .. ingredient
    local ingredient_item = game:get_item(ingredient)
    if not ingredient_item:has_amount(quantity) then
      can_craft = false
    end
  end

  if can_craft then
    game:start_dialog("menus.crafting.confirm", function(answer)
      if answer == 1 then
        for i, list_item in ipairs(recipe) do
          local ingredient, quantity = list_item.ingredient, list_item.quantity
          ingredient = "materials/crafting/" .. ingredient
          local ingredient_item = game:get_item(ingredient)
          ingredient_item:remove_amount(quantity)
        end
        result_item:set_variant(1)
        result_item:set_amount(result_item:get_max_amount())
        sol.audio.play_sound"cooking_meal"
        result_item:show_popup()
        --TODO: add visual elements, better sound effect, etc.
        menu:update_objects()
        --Stats:
        local num_crafted_items = game:get_value("num_crafted_items") or 0
        num_crafted_items = num_crafted_items + 1
        game:set_value("num_crafted_items", num_crafted_items)
        --Achievements:
        sol.achievements.unlock("ach_misc_crafted")
        if num_crafted_items >= 3 then sol.achievements.unlock("ach_misc_crafted_several") end
        if num_crafted_items >= 8 then sol.achievements.unlock("ach_misc_crafted_max") end
      end
    end)
  else
    sol.audio.play_sound"wrong"
  end
end


return menu
