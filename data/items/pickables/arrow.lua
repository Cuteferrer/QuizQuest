local item = ...
local game = item:get_game()


function item:on_started()
  item:set_brandish_when_picked(false)
  item:set_shadow("shadows/shadow_small")
end


function item:on_pickable_created(pickable)
  if not game:has_item("inventory/bow") then
    pickable:remove()
  end
end


function item:on_obtained(variant)
  local amounts = {1, 3, 5, 10}
  game:get_item("inventory/bow"):add_amount(amounts[variant])
end
