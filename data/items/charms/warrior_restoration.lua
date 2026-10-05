--Restores some magic when killing an enemy

local item = ...
local game = item:get_game()

local life_amount = 1
local magic_amount = 5

function item:on_started()
  local savegame_variable = "possession_charm_warrior_restoration"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3

  game.event_manager:subscribe("on_enemy_killed", function(enemy)
    if game:is_charm_equipped(item:get_name()) then
      game:add_life(life_amount)
      game:add_magic(magic_amount)
    end
  end)
end

