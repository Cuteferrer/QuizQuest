local item = ...
local game = item:get_game()

local frequency = 500
local amount = 1


function item:on_started()
  local savegame_variable = "possession_charm_gradual_magic"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3

end

function item:on_activated()
  item.effect_timer = sol.timer.start(game, frequency, function()
    game:add_magic(amount)
    return true
  end)
  item.effect_timer:set_suspended_with_map(true)
end


function item:on_unequipped()
  if item.effect_timer then
    item.effect_timer:stop()
  end
end
