--[[
Helper function, provides common behavavior for all items in several directories
--]]

local manager = {}
local game_meta = sol.main.get_metatable("game")

local all_materials = {}

animals = sol.main.get_items_in_directory("items/materials/animal")
ingredients = sol.main.get_items_in_directory("items/materials/ingredients")
minerals = sol.main.get_items_in_directory("items/materials/mineral")
monsters = sol.main.get_items_in_directory("items/materials/monster")
plants = sol.main.get_items_in_directory("items/materials/plant")
local all_tables = {animals, ingredients, minerals, monsters, plants}
for _, mat_table in pairs(all_tables) do
  for _, material in pairs(mat_table) do
    all_materials[material] = material
  end
end

function manager:get_all_materials()
  return all_materials
end


game_meta:register_event("on_started", function(game)
  --Create common behavior for all materials
  for _, item_entry in pairs(all_materials) do
    local item = game:get_item(item_entry)
    local save_name = item:get_name():gsub("/", "_")
    item:set_savegame_variable("possession_" .. save_name)
    item:set_amount_savegame_variable("amount_" .. save_name)
    item:set_brandish_when_picked(not game:has_item(item:get_name()))

    item:register_event("on_obtaining", function(item, variant, savegame_var)
      item:set_brandish_when_picked(not game:has_item(item:get_name()))
      item:add_amount(variant)
    end)

    function item:on_using()
      if item.heal_amount then
        if item:has_amount(1) then
          game:add_life(item.heal_amount)
          item:remove_amount(1)
        else
          sol.audio.play_sound"wrong"
        end
      end
      item:set_finished()
    end
  end
end)


return manager