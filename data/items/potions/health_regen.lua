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
    local rate = 3000
    local amount = 1
    local duration = 60000
    local elapsed_time = 0
    sol.timer.start(game, rate, function()
      elapsed_time = elapsed_time + rate
      game:add_life(amount)
      if elapsed_time < duration then return true end
    end)
  end
  item:set_finished()
end


function item:on_obtaining()
  item:add_amount(1)
end
