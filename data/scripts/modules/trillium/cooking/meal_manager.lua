-- Automatically creates common behavior for all items in the "items/meals" directory
--Just a convenience function

local game_meta = sol.main.get_metatable"game"
local manager = {}

local all_materials = sol.main.get_items_in_directory("items/meals")

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
    --print("For item:", item:get_name(), "set savegame variable", item:get_savegame_variable())
    item:set_brandish_when_picked(not game:has_item(item:get_name()))

    function item:on_obtaining(variant)
      item:set_brandish_when_picked(not game:has_item(item:get_name()))
      item:add_amount(variant)
    end

    if not item.on_using then
      function item:on_using()
        if item.heal_amount and game:get_life() < game:get_max_life() then
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

  end
end)

return manager
