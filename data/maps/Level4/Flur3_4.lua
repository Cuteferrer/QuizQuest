-- Lua script of map Level4/Flur3_4.
-- Flur 3 (Pausenhalle mit Saeulen)
-- Ein Lehrer versperrt den Weg und stellt PM-Fragen.

local map = ...
local hallway_quiz = require("scripts/level4/hallway_quiz")

function map:on_started()
  hallway_quiz.setup(map, {
    category = "PM",
    done_key = "level4_flur3_done",
    dialog   = "level4.flur3",
    aside    = { 48, 197 },
  })
end
