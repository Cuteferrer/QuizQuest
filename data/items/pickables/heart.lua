local item = ...
local game = item:get_game()


function item:on_started()
  item:set_brandish_when_picked(false)
  item:set_shadow("shadows/shadow_small")
end

function item:on_obtained()
  game:add_life(2)
end
