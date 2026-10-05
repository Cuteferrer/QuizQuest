--Creates a game object:
sol.modules.get_object("multi_events")
local game_initializer = require("scripts/initial_game")

local manager = {}
local last_loaded_filename = "save_1"

function manager:create(filename)
  -- Create the game
  local exists = sol.game.exists(filename)
  local game = sol.game.load(filename)
  --If the game wasn't loaded from a save file, init the new game:
  if not exists then
    game_initializer:initialize_new_savegame(game)
  end

  --Set starting location:
  local saved_starting_location = game:get_value("checkpoint_map")
  if saved_starting_location then game:set_starting_location(saved_starting_location) end

  return game
end


return manager

