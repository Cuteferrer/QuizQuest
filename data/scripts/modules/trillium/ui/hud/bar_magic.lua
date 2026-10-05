local builder_builder = require"scripts/modules/trillium/ui/hud/bar_builder_builder"

local builder = builder_builder:new(game, {
  max_amount_function = function() return sol.main.get_game():get_max_magic() end,
  current_amount_function = function() return sol.main.get_game():get_magic() end,
  draw_ratio = 1,
  color = "teal",
  check_frequency = 40,
})

return builder
