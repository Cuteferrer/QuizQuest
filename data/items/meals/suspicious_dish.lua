local item = ...
local game = item:get_game()

item.heal_amount = 1

function item:on_using()
  local heal_amount = math.random(-4, 2)
  game:set_life(game:get_life() + heal_amount)
end
