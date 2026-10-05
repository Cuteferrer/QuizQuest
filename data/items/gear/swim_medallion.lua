local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_swim_medallion")
end

function item:on_obtained(variant)
  game:set_max_oxygen_level(200)
end
