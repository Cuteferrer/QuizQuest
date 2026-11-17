-- Lua script of map Level4/Flur2_4.
-- Flur 2 (langer Gang mit Spinden)
-- Ein Lehrer versperrt den Weg und stellt DEV-Fragen.

local map = ...
local hallway_quiz = require("scripts/level4/hallway_quiz")

function map:on_started()
  hallway_quiz.setup(map, {
    category = "DEV",
    done_key = "level4_flur2_done",
    dialog   = "level4.flur2",
    aside    = { 240, 37 },
  })
end
