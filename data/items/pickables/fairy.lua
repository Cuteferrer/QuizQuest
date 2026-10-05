local item = ...
local game = item:get_game()


function item:on_started()
  item:set_brandish_when_picked(false)
  item:set_shadow("shadows/shadow_small")
end

function item:on_obtained()
  game:add_life(game:get_max_life())
end

function item:on_pickable_created(pickable)
  local m = sol.movement.create"random"
  m:start(pickable)
end

