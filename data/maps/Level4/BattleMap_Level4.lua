local map = ...
local game = map:get_game()
local quiz_menu = require("scripts/quiz_menu")

local quiz_ids = {
    "AE2_WISO_Q001",
    "AE2_WISO_Q002",
    "AE2_WISO_Q003",
    "AE2_WISO_Q004",
    "AE2_WISO_Q005",
    "AE2_WISO_Q006",
    "AE2_WISO_Q007",
    "AE2_WISO_Q008",
    "AE2_WISO_Q009",
    "AE2_WISO_Q010",
    "AE2_WISO_Q011",
    "AE2_WISO_Q012",
    "AE2_WISO_Q013",
    "AE2_WISO_Q014",
    "AE2_WISO_Q015",
    "AE2_WISO_Q016",
    "AE2_WISO_Q017",
    "AE2_WISO_Q018",
    "AE2_WISO_Q019",
    "AE2_WISO_Q020",
    "AE2_WISO_Q021",
    "AE2_WISO_Q022",
    "AE2_WISO_Q023",
    "AE2_WISO_Q024",
    "AE2_WISO_Q025",
}

-- Jedes Level (Room1_4 .. Room5_4) bekommt 5 Fragen aus quiz_ids:
-- Level 1 = Fragen 1-5, Level 2 = Fragen 6-10, ..., Level 5 = Fragen 21-25.
local QUESTIONS_PER_LEVEL = 5

-- Ermittelt das Level aus der Map, von der der Spieler kommt (z.B. "Level4/Room3_4" -> 3).
local function get_level()
	local level = tonumber(tostring(game.quiz_return_map):match("Room(%d+)_4"))
	return level or 1
end

-- Liefert die Fragen-IDs fuer ein Level.
local function get_level_quiz_ids(level)
	local ids = {}
	local first = (level - 1) * QUESTIONS_PER_LEVEL + 1
	for i = first, first + QUESTIONS_PER_LEVEL - 1 do
		if quiz_ids[i] then
			ids[#ids + 1] = quiz_ids[i]
		end
	end
	return ids
end

local function start_quiz()
	local hero = map:get_hero()
	hero:freeze()
  local level_quiz_ids = get_level_quiz_ids(get_level())
	quiz_menu.start(map, level_quiz_ids, game.shared_npc_animation_set, function(result, score)
	if result == "win" then
		-- Back to NPC
		hero:unfreeze()
		hero:teleport(game.quiz_return_map, game.quiz_return_dest)
  elseif result == "exit" then
		hero:unfreeze()
		hero:teleport(game.quiz_return_map, game.quiz_return_dest)
	else
		-- Quiz loose
		local black = sol.surface.create()
		black:fill_color({0, 0, 0})
		black:set_opacity(0)
		local overlay = {
			on_draw = function(_, dst) black:draw(dst, 0, 0) end,
		}
		sol.menu.start(map, overlay)

			black:fade_in(20, function()
				start_quiz()                 -- New quiz
				black:fade_out(20, function()
					sol.menu.stop(overlay) 
				end)
			end)
		end                           
	end)                                 
end                               

function map:on_opening_transition_finished()
	start_quiz()
end

function map:on_started()
	local animation_set_id = game.shared_npc_animation_set
	local npc2 = map:get_entity("npc2")
	if animation_set_id and npc2 then
		local old_sprite = npc2:get_sprite()
		if old_sprite then
			npc2:remove_sprite(old_sprite)
		end
		npc2:create_sprite(animation_set_id)
	end
end
