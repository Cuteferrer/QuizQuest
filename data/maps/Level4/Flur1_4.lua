-- Lua script of map Level4/Flur1_4.
-- Flur 1 (L-foermiger Gang)
-- Ein Lehrer versperrt den Weg und stellt UML-Fragen.

local map = ...
local hallway_quiz = require("scripts/level4/hallway_quiz")

function map:on_started()
  hallway_quiz.setup(map, {
    category = "UML",
    done_key = "level4_flur1_done",
    dialog   = "level4.flur1",
    aside    = { 24, 109 },
  })
end
