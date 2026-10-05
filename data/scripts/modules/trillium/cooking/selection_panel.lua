--The display panel for the cooking grid menu. Displays selected ingredients and predicted menu result (if recipe has been unlocked)
-- Licensed under MIT. Authored by Max Mraz.

local multi_events = sol.modules.get_object("multi_events")
local default_settings = sol.modules.get_object("trilmenu_grid_defaults")

local factory = {}
local menu_prototype = {}
multi_events:enable(menu_prototype)
local menu_metatable = {__index = menu_prototype}

local max_ingredients = 4

menu_prototype:register_event("on_started", function(self)
  local menu = self

  menu.background_surface = sol.surface.create(menu.width, menu.height)
  menu.background_surface:fill_color(menu.background_color)
  if menu.background_png then
    menu.background_surface = sol.surface.create(menu.background_png)
  end
  if menu.background_9slice_config then
    menu.background_surface = sol.modules.get_object("trilmenu_nineslice").get_surface(menu.background_9slice_config)
  end
  menu.ingredients_surface = sol.surface.create(menu.width, menu.height)
  menu.recipe_surface = sol.surface.create(menu.width, menu.ingredient_height)

  menu:update()
end)


function menu_prototype:notify(grid_menu)
  local menu = self
  menu.selected_ingredients = grid_menu.selected_ingredients or {}
  menu.current_recipe = grid_menu:get_current_recipe()
  menu:update()
end


function menu_prototype:update()
  local menu = self
  local game = sol.main.get_game()
  menu.ingredients_surface:clear()
  menu.recipe_surface:clear()
  --Draw ingredients
  for i = 1, max_ingredients do
    local surface = sol.surface.create(menu.width, menu.ingredient_height)
    surface:fill_color(menu.cell_color)
    local ing_object = menu.selected_ingredients and menu.selected_ingredients[i]
    if ing_object then
      local sprite = sol.sprite.create("entities/items")
      sprite:set_animation(ing_object.name)
      sprite:draw(surface, 16, 28)
      local txt_surface = sol.text_surface.create({
        font = menu.font,
        font_size = menu.font_size,
        font_color = menu.font_color,
        text = ing_object.food_name
      })
      txt_surface:draw(surface, 32, 16)
    end
    surface:draw(menu.ingredients_surface, 8,  (menu.ingredients_margin + menu.ingredient_height) * (i - 1))
  end

  --Draw resultant recipe, or ??? if not unlocked
  if menu.current_recipe then
    local txt_surface = sol.text_surface.create({
      font = menu.font,
      font_size = menu.font_size,
      font_color = menu.font_color,
    })

    if game:get_value("recipe_unlocked_" .. menu.current_recipe.recipe_name) then --check if recipe is unlocked
      txt_surface:set_text(menu.current_recipe.recipe_name)
      local sprite = sol.sprite.create("entities/items")
      sprite:set_animation("meals/" .. menu.current_recipe.recipe_name)
      sprite:draw(menu.recipe_surface, 24, 22)
    else
      txt_surface:set_text("???")
    end
    txt_surface:draw(menu.recipe_surface, 40, 16)
  end

end


menu_prototype:register_event("on_draw", function(self, screen)
  local menu = self
  menu.background_surface:draw(screen, menu.origin_x + menu.background_offset.x, menu.origin_y + menu.background_offset.y)
  menu.ingredients_surface:draw(screen, menu.origin_x, menu.ingredients_y + menu.origin_y)
  menu.recipe_surface:draw(screen, menu.origin_x, menu.recipe_y + menu.origin_y)
end)

function menu_prototype:fade_in(speed)
  speed = speed or 5
  self.background_surface:fade_in(speed)
  self.ingredients_surface:fade_in(speed)
  self.recipe_surface:fade_in(speed)
end


function factory.create(config)
    local menu = {}
    config = config or {}
    menu.width = config.panel_size and config.panel_size.width or 183
    menu.height = config.panel_size and config.panel_size.height or 200
    menu.origin_x = config.origin and config.origin.x or 30
    menu.origin_y = config.origin and config.origin.y or 40
    menu.recipe_y = config.recipe_y or 155
    menu.ingredients_y = config.ingredients_y or 8
    menu.ingredient_height = config.ingredient_height or 32
    menu.ingredients_margin = config.ingredients_margin or 4
    menu.font = config.font or default_settings.font
    menu.font_size = config.font_size or default_settings.font_size
    menu.font_color = config.font_color or default_settings.font_color
    menu.background_color = config.background_color or {0,0,0,0}
    menu.background_offset = config.background_offset or {x=0, y=0}
    menu.background_png = config.background_png
    menu.background_9slice_config = config.background_9slice_config
    menu.cell_color = config.cell_color or {0,0,0,0}

    setmetatable(menu, menu_metatable)

    return menu
end

return factory