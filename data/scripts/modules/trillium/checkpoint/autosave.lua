--[[
Autosaves the game every 60 seconds
--]]

local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"

--Save when starting on a new map:
map_meta:register_event("on_opening_transition_finished", function(map)
  map:get_game():save() --autosave when changing maps - NOTE: DON'T SAVE POSITION HERE because it can be off screen or in walls for some map transitions
end)

--Save every 60s or so
game_meta:register_event("on_started", function(game)
  sol.timer.start(game, 60 * 1000, function()
    game:save()
  end)
end)

