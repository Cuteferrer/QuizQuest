-- Lua script of map Level4/Room5_4 (Pruefungsraum, letzter Raum von Level 4).
-- Der Ausgang oben (Sensor "level_exit") fuehrt spaeter zum naechsten Level.

local map = ...
local game = map:get_game()
-- Schueler-NPC: startet das Quiz im Level-4-Battleraum
function Room5_4_Schueler:on_interaction()
  game.quiz_return_map  = map:get_id()          -- current map id
  game.quiz_return_dest = "near_npc"            -- destination on the map near NPC
  game.shared_npc_animation_set = Room5_4_Schueler:get_sprite():get_animation_set()
  map:get_hero():teleport("Level4/BattleMap_Level4", "start")
end


-- TODO: Hier die Map und Destination des naechsten Levels eintragen,
-- z.B. NEXT_LEVEL_MAP = "Level5/Room1_5" und NEXT_LEVEL_DEST = "start".
local NEXT_LEVEL_MAP = nil
local NEXT_LEVEL_DEST = nil

function map:on_started()
  local level_exit = map:get_entity("level_exit")
  function level_exit:on_activated()
    if NEXT_LEVEL_MAP then
      map:get_hero():teleport(NEXT_LEVEL_MAP, NEXT_LEVEL_DEST)
    else
      game:start_dialog("level4.exit_todo")
    end
  end
end
