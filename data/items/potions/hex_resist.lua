local item = ...
local game = item:get_game()

function item:on_started()
  local save_name = item:get_name():gsub("/", "_")
  item:set_savegame_variable("possession_" .. save_name)
  item:set_amount_savegame_variable("amount_" .. save_name)
end

function item:on_using()
  if item:has_amount(1) then
    item:remove_amount(1)
    local rate_mult, amount_mult = game:get_magic_regen_multiplier()
    if rate_mult < 1 then rate_mult = 1 end
    if amount_mult < 1 then amount_mult = 1 end
    game:set_magic_regen_multiplier(rate_mult, amount_mult)
    game:start_status_immunity("hex", 10 * 60000)
  end
  item:set_finished()
end


function item:on_obtaining()
  item:add_amount(1)
end
