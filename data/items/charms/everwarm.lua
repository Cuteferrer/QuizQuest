local item = ...
local game = item:get_game()

local status = "cold"

function item:on_started()
  local savegame_variable = "possession_charm_everwarm"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3
end

function item:on_activated()
  local hero = game:get_hero()
  hero:start_status_immunity(status, "infinite")
end


function item:on_unequipped()
  local hero = game:get_hero()
  hero:stop_status_immunity(status)
end
