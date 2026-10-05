local item = ...
local game = item:get_game()

--Coin pickables can get sucked toward the hero if they're close.
--Set this function to return false if you don't want this behavior, true if you always want it, or maybe check if the hero has acquired some item
local money_magnitizes_to_hero = function()
  return true
end
local magnet_threshold = 48
--How much money each variant of this item is worth
local amount_by_variant = {1, 5, 10, 20, 50, 100}

function item:on_started()
  item:set_brandish_when_picked(false)
  item:set_shadow("shadows/shadow_small")
  item:set_sound_when_picked("picked_money")
end

function item:on_obtained(var)
  game:add_money(amount_by_variant[var])
end

function item:on_pickable_created(pickable)
  if not money_magnitizes_to_hero() then return end
  local hero = game:get_hero()
  sol.timer.start(pickable, 500, function()
    if pickable:get_distance(hero) < magnet_threshold then
      local m = sol.movement.create"target"
      m:set_speed(100)
      m:start(pickable)
    else
      return true
    end
  end)
end