-- scripts/level4/hallway_quiz.lua
-- Gemeinsame Logik fuer die Flure in Level 4:
-- Ein Lehrer-NPC versperrt den Flur. Sprichst du ihn an, startet ein Quiz
-- (Map "battle"). Gewinnst du, wird der Flur dauerhaft freigegeben
-- (Savegame-Wert cfg.done_key) und der Lehrer tritt zur Seite.
--
-- Benutzung in einer Map:
--   local hallway_quiz = require("scripts/level4/hallway_quiz")
--   function map:on_started()
--     hallway_quiz.setup(map, {
--       category = "UML",                 -- UML | DEV | PM | WISO
--       done_key = "level4_flur1_done",   -- Savegame-Wert
--       dialog   = "level4.flur1",        -- Dialog-Prefix (.intro / .done)
--       aside    = { 24, 109 },           -- Position des NPC nach dem Sieg
--     })
--   end
--
-- Erwartete Entities in der Map:
--   npc  "lehrer"         der Fragensteller
--   wall "barrier_*"      unsichtbare Sperre neben dem NPC
--   destination "near_npc" dorthin kommt der Held nach dem Quiz zurueck

local hallway_quiz = {}

local QUESTIONS_PER_CATEGORY = 25
local QUIZ_SIZE = 4

if os and os.time then
  math.randomseed(os.time())
end

-- Waehlt QUIZ_SIZE zufaellige, verschiedene Fragen einer Kategorie.
local function pick_questions(category)
  local pool = {}
  for i = 1, QUESTIONS_PER_CATEGORY do
    pool[#pool + 1] = string.format("AE2_%s_Q%03d", category, i)
  end
  local ids = {}
  for i = 1, math.min(QUIZ_SIZE, #pool) do
    local j = math.random(i, #pool)
    pool[i], pool[j] = pool[j], pool[i]
    ids[#ids + 1] = pool[i]
  end
  return ids
end

function hallway_quiz.setup(map, cfg)
  local game = map:get_game()
  local npc = map:get_entity(cfg.npc or "lehrer")

  local function open_hallway()
    map:set_entities_enabled("barrier", false)
    if cfg.aside then
      npc:set_position(cfg.aside[1], cfg.aside[2])
    end
  end

  if game:get_value(cfg.done_key) then
    open_hallway()
  end

  function npc:on_interaction()
    if game:get_value(cfg.done_key) then
      game:start_dialog(cfg.dialog .. ".done")
      return
    end

    game:start_dialog(cfg.dialog .. ".intro", function()
      -- Daten fuer maps/battle.lua
      game.quiz_return_map = map:get_id()
      game.quiz_return_dest = "near_npc"
      game.quiz_ids = pick_questions(cfg.category)
      game.quiz_win_value = cfg.done_key
      game.shared_npc_animation_set = npc:get_sprite():get_animation_set()
      map:get_hero():teleport("battle", "start")
    end)
  end
end

return hallway_quiz
