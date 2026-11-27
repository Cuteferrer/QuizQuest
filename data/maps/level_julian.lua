-- Lua script of map level_julian.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- https://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Gegner: Ansprechen startet den Kampf (Quiz) in battle_julian.
-- battle_julian waehlt die Fragen passend zum Gegner aus (5 pro Gegner, Katalog AE2 Entwicklung).
-- Nach dem Quiz kehrt der Held zum Ziel "near_<gegner>" vor dem Gegner zurueck.
-- Besiegte Gegner verschwinden; so gibt der Waechter gegner_4 den Weg zum Boss frei.
local enemies = { "gegner_1", "gegner_2", "gegner_3", "gegner_4", "boss" }

-- Savegame-Wert, der nach einem Sieg gesetzt wird (z.B. "level_julian_gegner_4_besiegt").
local function defeated_value(name)
  return "level_julian_" .. name .. "_besiegt"
end

for _, name in ipairs(enemies) do
  local npc = map:get_entity(name)
  function npc:on_interaction()
    game.quiz_return_map  = map:get_id()          -- current map id
    game.quiz_return_dest = "near_" .. name       -- destination on the map near NPC
    game.quiz_win_value   = defeated_value(name)  -- set by battle_julian after a win
    game.shared_npc_animation_set = npc:get_sprite():get_animation_set()
    -- next map transition
    map:get_hero():teleport("battle_julian", "start")
  end
end

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- Besiegte Gegner entfernen.
  for _, name in ipairs(enemies) do
    if game:get_value(defeated_value(name)) then
      map:get_entity(name):remove()
    end
  end

  -- Gegner-NPCs stehen still:
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
