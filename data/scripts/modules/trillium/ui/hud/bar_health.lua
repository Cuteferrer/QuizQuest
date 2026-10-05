local builder_builder = require"scripts/modules/trillium/ui/hud/bar_builder_builder"

local builder = builder_builder:new(game, {
  max_amount_function = function() return sol.main.get_game():get_max_life() end,
  current_amount_function = function() return sol.main.get_game():get_life() end,
  draw_ratio = 2,
  color = "red",
  check_frequency = 20,
})

return builder
