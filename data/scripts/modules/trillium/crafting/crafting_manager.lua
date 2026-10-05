--[[
Created by Max Mraz, licensed MIT

Crafting system. Available "recipes" are shown in a menu, along with the necessary materials to craft them
If the player has the required materials, the item can be created

The uncrafting menu does this in reverse, disassembling crafted items to return the used materials
--]]

local game_meta = sol.main.get_metatable"game"

function game_meta:start_crafting()
  sol.menu.start(self, require"scripts/modules/trillium/crafting/crafting_menu")
end

function game_meta:start_uncrafting()
  sol.menu.start(self, require"scripts/modules/trillium/crafting/uncrafting_menu")
end
