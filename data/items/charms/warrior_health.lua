--Restores some life when killing an enemy

local item = ...
local game = item:get_game()

local amount = 3 --life restored when killing enemy

function item:on_started()
  local savegame_variable = "possession_charm_warrior_health"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3

  game.event_manager:subscribe("on_enemy_killed", function(enemy)
    if game:is_charm_equipped(item:get_name()) then
      game:add_life(amount)      
    end
  end)
end

