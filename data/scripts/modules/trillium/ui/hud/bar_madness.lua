local builder_builder = require"scripts/modules/trillium/ui/hud/bar_builder_builder"

local builder = builder_builder:new(game, {
  max_amount_function = function()
    return sol.main.get_game():get_status_effect_resistance("madness")
  end,
  current_amount_function = function() return sol.main.get_game():get_hero():get_status_effect_buildup("madness") end,
  draw_ratio = 3,
  color = "madness", 
  background_opacity = 128,
  --background_sprite = "hud/stat_bars/background_minimal",
  --endcap_sprite = "hud/stat_bars/endcap_minimal",
  check_frequency = 40,
  time_before_fade = 1000,
  amount_changed_function = function(bar)
    if bar.current_amount >= (sol.main.get_game():get_status_effect_resistance("madness")) then
      bar.foreground:set_animation"flashing"
      sol.timer.start(bar, 500, function()
        bar.foreground:set_animation"bar"
      end)
    end
  end
})

return builder
