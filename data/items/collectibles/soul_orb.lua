local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_soul_orb")
  item:set_amount_savegame_variable("amount_soul_orb")
end

function item:on_obtained()
  item:add_amount(1)
end
