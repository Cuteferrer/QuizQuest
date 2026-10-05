local item = ...
local game = item:get_game()

local amount = 900 --how much longer in ms invincibility lasts after taking damage

function item:on_started()
  local savegame_variable = "possession_charm_wounded_evasion"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 2
end

function item:on_equipped()
  local current_bonus = game:get_value("hurt_iframes_bonus") or 0
  game:set_value("hurt_iframes_bonus", current_bonus + amount)
end

function item:on_unequipped()
  local current_bonus = game:get_value("hurt_iframes_bonus") or 0
  game:set_value("hurt_iframes_bonus", current_bonus - amount)
end
