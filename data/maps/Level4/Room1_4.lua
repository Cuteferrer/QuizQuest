-- Lua script of map Level4/Room1_4.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- https://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()


function Room1_4_Schueler2:on_interaction()
game.quiz_return_map  = map:get_id()          -- current map id
game.quiz_return_dest = "near_npc"            -- destination on the map near NPC
	game.shared_npc_animation_set = Room1_4_Schueler2:get_sprite():get_animation_set()
	-- next map transition
	map:get_hero():teleport("Level4/BattleMap_Level4", "start")
end
-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
