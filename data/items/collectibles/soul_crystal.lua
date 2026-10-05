local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_soul_crystal")
  item:set_amount_savegame_variable("amount_soul_crystal")
end

function item:on_obtained(variant)
  item:add_amount(1)
end
