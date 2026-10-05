--Replenishes magic when taking damage

local item = ...
local game = item:get_game()

local amount = 10

function item:on_started()
  local savegame_variable = "possession_charm_mp_solace"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 2

  game.event_manager:subscribe("on_hurt", function()
    if item.active then
      game:add_magic(amount)
    end
  end)
end

