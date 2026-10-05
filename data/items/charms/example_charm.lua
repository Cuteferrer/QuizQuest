local item = ...
local game = item:get_game()

function item:on_started()
  local savegame_variable = "possession_charm_"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 1

  game.event_manager:subscribe("on_example", function()
    if game:is_charm_equipped(item:get_name()) then

    end
  end)
end

function item:on_equipped()

end


function item:on_activated()

end


function item:on_unequipped()

end
