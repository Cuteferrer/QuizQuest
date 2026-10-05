-- This module gives access to equipment related info.

-- Usage:
-- require("scripts/equipment")

require("scripts/multi_events")

local function initialize_equipment_features(game)

  game:register_event("on_command_pressed", function(game, command)
    equipment_disabled = game:get_value("equipment_disabled")
    if equipment_disabled then
      if command == "item_1" or command == "item_2" then
        return true
      end
    end
    return false
  end)

  function game:disable_equipment()
    game:set_value("equipment_disabled", true)
  end

  function game:enable_equipment()
    game:set_value("equipment_disabled", false)
  end
end

-- Set up equipment features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_equipment_features)

return true
