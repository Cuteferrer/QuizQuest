local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_charm_stone")
  item:set_amount_savegame_variable("amount_charm_stone")
end

function item:on_obtained(variant)
  item:add_amount(1)
  local old_amount = game:get_value("charm_slots")
  local new_amount = old_amount + 1
  game:set_value("charm_slots", new_amount)
end
