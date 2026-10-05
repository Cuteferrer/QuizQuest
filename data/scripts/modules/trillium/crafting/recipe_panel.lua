--The display panel for the cooking grid menu. Displays selected ingredients and predicted menu result (if recipe has been unlocked)
-- Licensed under MIT. Authored by Max Mraz.

local multi_events = sol.modules.get_object("multi_events")
local default_settings = sol.modules.get_object("trilmenu_grid_defaults")

local factory = {}
local menu_prototype = {}
multi_events:enable(menu_prototype)
local menu_metatable = {__index = menu_prototype}

local max_ingredients = 4 --maximum number of ingredients a recipe can require

menu_prototype:register_event("on_started", function(self)
  local menu = self

  menu.background_surface = sol.surface.create(menu.width, menu.height)
  menu.background_surface:fill_color(menu.background_color)
  if menu.background_png then
    menu.background_surface = sol.surface.create(menu.background_png)
  end
  if menu.background_9slice then
    menu.background_surface = sol.modules.get_object("trilmenu_nineslice").get_surface{
      width = menu.width, height = menu.height,
      source_png = menu.background_9slice,
      tile_width = 8, tile_height = 8,
    }
  end
  menu.ingredients_surface = sol.surface.create(menu.width, menu.height)
  menu.recipe_surface = sol.surface.create(menu.width, menu.ingredient_height + 4)
  menu.break_line = sol.surface.create(menu.width - 16, 1)
  menu.break_line:fill_color(menu.break_line_color)

  --menu:update()
end)


function menu_prototype:notify(grid_menu)
  local menu = self
  menu.selected_ingredients = grid_menu.selected_ingredients or {}
  local ob = grid_menu:get_selected_object() or {}
  menu.selected_recipe_name = ob.name
  menu.selected_recipe_table = ob.recipe_table
  menu:update()
end


function menu_prototype:update()
  local menu = self
  local game = sol.main.get_game()
  menu.ingredients_surface:clear()
  menu.recipe_surface:clear()

  --If you've selected an empty space on the recipe grid:
  if menu.selected_recipe_name == nil then return end

  --Draw selected recipe result item
  --Sprite
  local result_sprite = sol.sprite.create"entities/items"
  result_sprite:set_animation(menu.selected_recipe_name)
  result_sprite:draw(menu.recipe_surface, 16, 16)
  --Name of recipe
  local recipe_name_string = sol.language.get_string("items." .. menu.selected_recipe_name:gsub("/", "."))
  local recipe_txt = sol.text_surface.create({
    font = menu.font,
    font_size = menu.font_size,
    font_color = menu.font_color,
    text = recipe_name_string,
  })
  recipe_txt:draw(menu.recipe_surface, 32, 16)
  menu.break_line:draw(menu.recipe_surface, 8, menu.ingredient_height + 3)
  

  --Draw ingredients
  for i, list_item in ipairs(menu.selected_recipe_table) do
    local ingredient, quantity_needed = list_item.ingredient, list_item.quantity
    local surface = sol.surface.create(menu.width, menu.ingredient_height)
    surface:fill_color(menu.cell_color)
    --Draw sprite
    local sprite = sol.sprite.create("entities/items")
    sprite:set_animation("materials/crafting/" .. ingredient)
    sprite:draw(surface, 16, menu.ingredient_height - 5)
    --Draw ingredient name:
    local ing_name_string = sol.language.get_string("items.materials.crafting." .. ingredient)
    local ing_name_txt = sol.text_surface.create({
      font = menu.font,
      font_size = menu.font_size,
      font_color = menu.font_color,
      text = ing_name_string,
    })
    ing_name_txt:draw(surface, 32, 14)
    --Draw quantity like (3 / 5)
    local quantity_held = game:get_item("materials/crafting/" .. ingredient):get_amount()
    local txt_surface = sol.text_surface.create({
      font = menu.font,
      font_size = menu.font_size,
      font_color = menu.font_color,
      text = quantity_held .. " / " .. quantity_needed,
    })
    if quantity_needed > quantity_held then txt_surface:set_color_modulation{150,150,150,255} end
    txt_surface:draw(surface, menu.width - 32, 14)
    surface:draw(menu.ingredients_surface, 0,  (menu.ingredients_margin + menu.ingredient_height) * (i))
  end

end


menu_prototype:register_event("on_draw", function(self, screen)
  local menu = self
  menu.background_surface:draw(screen, menu.origin_x + menu.background_offset.x, menu.origin_y + menu.background_offset.y)
  menu.ingredients_surface:draw(screen, menu.origin_x, menu.ingredients_y + menu.origin_y)
  menu.recipe_surface:draw(screen, menu.origin_x, menu.recipe_y + menu.origin_y)
end)


function factory.create(config)
    local menu = {}
    config = config or {}
    menu.width = config.panel_size and config.panel_size.width or 176
    menu.height = config.panel_size and config.panel_size.height or 176
    menu.origin_x = config.origin and config.origin.x or 30
    menu.origin_y = config.origin and config.origin.y or 40
    menu.recipe_y = config.recipe_y or 8
    menu.ingredients_y = config.ingredients_y or 16
    menu.ingredient_height = config.ingredient_height or 24
    menu.ingredients_margin = config.ingredients_margin or 4
    menu.font = config.font or default_settings.font
    menu.font_size = config.font_size or default_settings.font_size
    menu.font_color = config.font_color or default_settings.font_color
    menu.background_color = config.background_color or {0,0,0,0}
    menu.background_9slice = config.background_9slice
    menu.background_offset = config.background_offset or {x=0, y=0}
    menu.background_png = config.background_png
    menu.cell_color = config.cell_color or {0,0,0,0}
    menu.break_line_color = config.break_line_color or sol.colors.ui_grey_dark

    setmetatable(menu, menu_metatable)

    return menu
end

return factory
