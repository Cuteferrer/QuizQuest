--[[
A custom entity just to be used as a marker when designing maps, or for other entities to reference. Is invisible during gameplay.
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_visible(false)
end
