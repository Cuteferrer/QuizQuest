local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_ogrestone")
end


function item:on_obtained()
  game:set_ability("lift", 1)
  local map = game:get_map()
  if map.reevaluate_block_weights then map:reevaluate_block_weights() end
end

