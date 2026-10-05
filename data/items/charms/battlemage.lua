--Replenishes magic when hitting an enemy

local item = ...
local game = item:get_game()

local amount = 5

function item:on_started()
  local savegame_variable = "possession_charm_battlemage"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 2

  game.event_manager:subscribe("on_enemy_attacked", function()
    if game:is_charm_equipped(item:get_name()) then
      game:add_magic(amount)
    end
  end)
end
