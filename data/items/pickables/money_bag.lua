local item = ...
local game = item:get_game()


--How much money each variant of this item is worth
local amount_by_variant = {20, 50, 100, 200}

function item:on_started()
  item:set_brandish_when_picked(false)
  item:set_shadow("shadows/shadow_small")
  item:set_sound_when_picked("picked_money")
end

function item:on_obtained(var)
  game:add_money(amount_by_variant[var])
end
