--[[
Created by Max Mraz, licensed MIT

A cooking system, similar to Zelda: Breath of the Wild
Choose ingredients from your inventory in a cooking menu,
the choices will be compared against a recipe list, the appropriate meal selected,
and that meal created.

It is assumed pertinent items are created in certain folders:
ingredients: items/materials/ingredients, and 
meals: items/meals
--]]

local game_meta = sol.main.get_metatable"game"

function game_meta:start_cooking()
  local game = self
  local cooking_menu = require"scripts/modules/trillium/cooking/ingredients_grid"
  sol.menu.start(game, cooking_menu)
end
