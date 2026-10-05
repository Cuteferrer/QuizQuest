local item = ...
local game = item:get_game()

function item:on_started()
  local savegame_variable = "possession_charm_quickstep"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 2
end

function item:on_equipped()
  local old_level = game:get_value("dash_level") or 1
  game:set_value("dash_level", old_level + 1)
end


function item:on_unequipped()
  local old_level = game:get_value("dash_level")
  game:set_value("dash_level", old_level - 1)
end
