local builder_builder = require"scripts/modules/trillium/ui/hud/bar_builder_builder"

local builder = builder_builder:new(game, {
  max_amount_function = function() return sol.main.get_game():get_max_stamina() end,
  current_amount_function = function() return sol.main.get_game():get_stamina() end,
  draw_ratio = 2,
  color = "green",
  check_frequency = 10,
})

return builder
