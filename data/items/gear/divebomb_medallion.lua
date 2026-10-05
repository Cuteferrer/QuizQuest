local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_divebomb_medallion")
end

function item:on_obtained(variant)
  game:set_value("jumping_shockwave_dive", true)
end
