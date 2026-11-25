-- Lua script of map level_julian.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- https://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- Gegner-NPCs (gegner_1 .. gegner_4, boss) stehen still:
  -- einige Gegner-Sprites starten sonst mit ihrer Lauf-Animation.
  for npc in map:get_entities_by_type("npc") do
    local sprite = npc:get_sprite()
    if sprite ~= nil and sprite:has_animation("stopped") then
      sprite:set_animation("stopped")
    end
  end
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
