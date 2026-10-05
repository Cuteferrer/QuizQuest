--Restores some magic when killing an enemy

local item = ...
local game = item:get_game()

local amount = 15

function item:on_started()
  local savegame_variable = "possession_charm_warrior_magic"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 2

  game.event_manager:subscribe("on_enemy_killed", function(enemy)
    if game:is_charm_equipped(item:get_name()) then
      game:add_magic(amount)
    end
  end)
end

