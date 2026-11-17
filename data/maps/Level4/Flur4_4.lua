-- Lua script of map Level4/Flur4_4.
-- Flur 4 (Slalom-Gang)
-- Ein Lehrer versperrt den Weg und stellt WISO-Fragen.

local map = ...
local hallway_quiz = require("scripts/level4/hallway_quiz")

function map:on_started()
  hallway_quiz.setup(map, {
    category = "WISO",
    done_key = "level4_flur4_done",
    dialog   = "level4.flur4",
    aside    = { 32, 69 },
  })
end
