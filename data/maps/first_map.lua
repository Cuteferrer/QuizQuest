-- Lua script of map first_map.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()


function npc1:on_interaction()
	-- Запоминаем набор анимаций текущего спрайта npc1.
game.quiz_return_map  = map:get_id()          -- id текущей карты
game.quiz_return_dest = "near_npc"            -- destination на этой карте рядом с NPC
	game.shared_npc_animation_set = npc1:get_sprite():get_animation_set()
	-- Переходим на другую карту.
	map:get_hero():teleport("battle", "start")
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
