local ingredients = sol.main.get_items_in_directory("items/materials/ingredients")

local allowed_objects = {}

local game = sol.main.get_game() --don't you dare require this menu until the game is running

--Set up ingredients as objects
for i = 1, #ingredients do
  local object = {}
  local item = game:get_item(ingredients[i])
  object.name = ingredients[i]
  object.heal_amount = item.heal_amount
  object.food_name = object.name:gsub("materials/ingredients/", "")
  object.bonus_type = item.bonus_type
  object.food_type = item.food_type
  object.sprite = "_item"
  object.text_function = function()
    local equip_item = sol.main.get_game():get_item(object.name)
    if equip_item and equip_item:has_amount() then
      return equip_item:get_amount()
    end
  end
  object.text_offset = { x = 18, y = 24}
  object.text_config = {
    font = "white_digits",
  }
  object.display_function = "_item"
  allowed_objects[i] = object
end

local config = {
  origin = {x = 8, y = 32},
  grid_size = {columns=5, rows=5},
  cell_size = {width=32, height=32},
  cell_spacing = 4,
  edge_spacing = 4,
  background_9slice_config = {
    width = 192, height = 192,
  },
  background_offset = {x = 0, y = -6},
  cell_png = "menus/inventory/circle_cell.png",
  cursor_sound = "cursor",
  fade_in_speed = 5,
}
config.allowed_objects = allowed_objects

local selection_panel_config = {
  origin = {x = 208, y = 26},
  background_9slice_config = {
    width = 192, height = 192,
  },
  cell_color = {100,100,100,25},
}
local selection_panel = require("scripts/modules/trillium/cooking/selection_panel").create(selection_panel_config)
local ingredient_name_panel = require("scripts/modules/trillium/cooking/ingredient_name_panel")
ingredient_name_panel.x, ingredient_name_panel.y = 8, 202
config.aux_menus = { selection_panel, ingredient_name_panel, }

local menu = sol.modules.get_object("trilmenu_grid").create(config)

menu:hide_hud_when_open()




----Above is menu stuff. Below is logic stuff. Mostly. Will separate into two scripts later. maybe -------------------------------------------------------



local ingredient_types_list = require("scripts/modules/trillium/cooking/ingredient_types_list")
local recipe_list = require("scripts/modules/trillium_config/game_data/cooking_recipes")
local result_modal = require("scripts/modules/trillium/cooking/result_modal")
result_modal.x, result_modal.y = 208 - 80, 120 - 16
local recipe_weighting_config = require("scripts/modules/trillium/cooking/recipe_weighting_config")
if (#recipe_list == 0) then print("Warning: no recipes configured in scripts/modules/trillium_config/game_data/cooking_recipes.lua") end

local max_ingredients = 4

menu:register_event("on_started", function(self)
  game:set_suspended(true)
  --Clear selected ingredients table
  menu.selected_ingredients = {}
end)

menu:register_event("on_finished", function(self)
  game:set_suspended(false)
end)


menu:register_event("on_command_pressed", function(self, command)
  local handled = false

  if command == "confirm" then
    handled = true
    if #menu.selected_ingredients < max_ingredients then
      menu:add_current_ingredient()
    else
      sol.audio.play_sound"wrong"
    end

  elseif command == "cancel" then
    handled = true
    if menu.selected_ingredients[1] then
      table.remove(menu.selected_ingredients)
    else
      sol.menu.stop(self)
    end

  elseif command == "item_1" or command == "item_2" then
    handled = true
    if #menu.selected_ingredients > 0 then
      menu:cook()
    else
      sol.audio.play_sound"wrong"
    end

  elseif command == "pause" then
    handled = true
    sol.menu.stop(menu)

  end

  menu:update_surface()

  return handled
end)


function menu:add_current_ingredient()
  local current_ingredient = menu:get_selected_object()
  local ingredient_item = game:get_item(current_ingredient.name)
  if ingredient_item:get_amount() > 0 then
    table.insert(menu.selected_ingredients, current_ingredient)
    sol.audio.play_sound"cooking_ingredient_add"
  else
    sol.audio.play_sound"wrong"
  end
end


function menu:get_current_recipe()
  if not menu.selected_ingredients or #menu.selected_ingredients < 1 then return nil end
  local possible_recipes = {}
  for recipe_name, recipe in pairs(recipe_list) do
    if menu:check_recipe_requirements(recipe) then
      recipe.recipe_name = recipe_name --just for ease of access
      possible_recipes[recipe_name] = recipe
    end
  end

  local result_recipe = menu:get_highest_priority_recipe(possible_recipes)
  if not result_recipe then
    result_recipe = recipe_list.suspicious_dish --Fail state recipe
  end
  return result_recipe
end


function menu:cook()
  local result_recipe = menu:get_current_recipe()
  --Show success modal:
  result_modal:set_result(result_recipe.recipe_name)
  sol.menu.start(menu, result_modal)
  sol.audio.play_sound"cooking_meal"
  --Unlock recipe
  game:set_value("recipe_unlocked_" .. result_recipe.recipe_name, true)
  --Add item and use up ingredients
  local meal_item = game:get_item("meals/" .. result_recipe.recipe_name)
  if not meal_item:get_savegame_variable() then
    print("Warning! Meal item: '" .. "meals/" .. result_recipe.recipe_name .. "' is not saved!")
  elseif not game:has_item("meals/" .. result_recipe.recipe_name) then
    meal_item:set_variant(1)
    meal_item:add_amount(1)
  else
    meal_item:add_amount(1)
    print("Added meal", meal_item:get_name(), meal_item:get_amount())
  end
  for _, ingredient in pairs(menu.selected_ingredients) do
    local ingredient_item = game:get_item(ingredient.name)
    ingredient_item:remove_amount(1)
  end
  menu.selected_ingredients = {}
  menu:update_objects()
end


function menu:check_recipe_requirements(recipe)
  --Copy the selected ingredients table so we can manipulate it just in this recipe check:
  local test_ingredients = {}
  for i, v in ipairs(menu.selected_ingredients) do
    test_ingredients[i] = v
  end
  local has_requirements = true
  --Check ingredients for specifics
  for req_key, requirement in ipairs(recipe) do
    if not ingredient_types_list[requirement] then --check to make sure the requirement is specific, not a type
      local can_make = false
      for ing_key, ingredient in pairs(test_ingredients) do
        if ingredient.food_name == requirement then
          can_make = true
          test_ingredients[ing_key] = nil --remove, you've used this ingredient
        end
      end
      if not can_make then has_requirements = false end
    end
  end
  --Check ingredients for types
  for req_key, requirement in ipairs(recipe) do
    if ingredient_types_list[requirement] then --check to make sure the requirement is an ingredient type
      local can_make = false
      for ing_key, ingredient in pairs(test_ingredients) do
        if ingredient.food_type == requirement then
          can_make = true
          test_ingredients[ing_key] = nil --remove, you've used this ingredient
        end
      end
      if not can_make then has_requirements = false end
    end
  end
  return has_requirements
end


function menu:get_highest_priority_recipe(possible_recipes)
  local complexity_points = recipe_weighting_config.recipe_complexity
  local specific_match_points = recipe_weighting_config.specific_matches
  local total_match_points = recipe_weighting_config.total_matches
  local order_mod = recipe_weighting_config.ingredient_order_mod
  local top_recipe
  for recipe_name, recipe in pairs(possible_recipes) do
    recipe.priority = 0
    recipe.num_ingredients = 0
    for ing_key, ingredient in ipairs(recipe) do
      recipe.num_ingredients = recipe.num_ingredients + 1 --just to keep track
      recipe.priority = recipe.priority + complexity_points --add points for recipe complexity (total ingredients in recipe)
      if not ingredient_types_list[ingredient] then
        recipe.priority = recipe.priority + specific_match_points --bonus points if it's a specific ingredient rather than a general ingredient type
      end
    end
    --increase recipe priority by total matches, including duplicates
    for i, ingredient in ipairs(menu.selected_ingredients) do
      for _, recipe_ingredient in ipairs(recipe) do
        if ingredient.food_name == recipe_ingredient or ingredient.food_type == recipe_ingredient then
          if order_mod then
            recipe.priority = recipe.priority + (total_match_points * (i ^ (order_mod * -1)))
          else
            recipe.priority = recipe.priority + (total_match_points)
          end
        end
      end
    end
    --print("Recipe:", recipe_name, "Num Ingredients:", recipe.num_ingredients, "..........", recipe.priority)
    if not top_recipe or (recipe.priority > top_recipe.priority) then
      top_recipe = recipe
    end
  end
  --print("===================")
  return top_recipe
end



return menu
