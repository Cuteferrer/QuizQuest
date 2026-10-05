local bar_factory = require"scripts/modules/trillium/ui/hud/bar_factory"
local builder_builder = {}

function builder_builder:new(game, bar_config)
  local bar_builder = {}

  function bar_builder:new(game, config)
    local mod_config = table.duplicate(bar_config)
    mod_config.x, mod_config.y = config.x, config.y
    mod_config.fade_on_suspend = config.fade_on_suspend
    local bar = bar_factory.new(mod_config)
    return bar
  end

  return bar_builder
end

return builder_builder

