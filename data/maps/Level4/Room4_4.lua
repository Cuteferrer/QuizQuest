-- Lua script of map Level4/Room4_4 (Lehrerzimmer).
-- This script is executed every time the hero enters this map.

-- See the Solarus Lua API documentation:
-- https://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
-- Schueler-NPC: startet das Quiz im Level-4-Battleraum
function Room4_4_Schueler:on_interaction()
  game.quiz_return_map  = map:get_id()          -- current map id
  game.quiz_return_dest = "near_npc"            -- destination on the map near NPC
  game.shared_npc_animation_set = Room4_4_Schueler:get_sprite():get_animation_set()
  map:get_hero():teleport("Level4/BattleMap_Level4", "start")
end


-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
