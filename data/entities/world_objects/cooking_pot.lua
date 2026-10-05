--[[
By Max Mraz, licensed MIT
Use to start the cooking menu
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
end

function entity:on_interaction()
  sol.timer.start(map, 10, function()
    game:start_cooking()
  end)
end
