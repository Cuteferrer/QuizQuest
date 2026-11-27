local map = ...
local game = map:get_game()
local quiz_menu = require("scripts/quiz_menu")

-- Fragenkatalog AE2 Entwicklung (questions/AE2_ENTWICKLUNG_Fragen.json).
-- Jeder Gegner aus level_julian bekommt 5 eigene Fragen (wie die Raeume in Level 4).
local quiz_ids_by_enemy = {
	gegner_1 = { "AE2_DEV_Q001", "AE2_DEV_Q002", "AE2_DEV_Q003", "AE2_DEV_Q004", "AE2_DEV_Q005" },
	gegner_2 = { "AE2_DEV_Q006", "AE2_DEV_Q007", "AE2_DEV_Q008", "AE2_DEV_Q009", "AE2_DEV_Q010" },
	gegner_3 = { "AE2_DEV_Q011", "AE2_DEV_Q012", "AE2_DEV_Q013", "AE2_DEV_Q014", "AE2_DEV_Q015" },
	gegner_4 = { "AE2_DEV_Q016", "AE2_DEV_Q017", "AE2_DEV_Q018", "AE2_DEV_Q019", "AE2_DEV_Q020" },
	boss     = { "AE2_DEV_Q021", "AE2_DEV_Q022", "AE2_DEV_Q023", "AE2_DEV_Q024", "AE2_DEV_Q025" },
}

-- Ermittelt den Gegner aus dem Ziel, zu dem der Spieler zurueckkehrt
-- (z.B. "near_gegner_3" -> "gegner_3").
local function get_enemy()
	return tostring(game.quiz_return_dest):match("^near_(.+)$")
end

-- Liefert die Fragen-IDs fuer den aktuellen Gegner.
local function get_enemy_quiz_ids()
	return quiz_ids_by_enemy[get_enemy()] or quiz_ids_by_enemy.gegner_1
end

local function start_quiz()
	local hero = map:get_hero()
	hero:freeze()
	quiz_menu.start(map, get_enemy_quiz_ids(), game.shared_npc_animation_set, function(result, score)
	if result == "win" then
		-- Sieg merken, damit der Gegner in level_julian verschwindet
		-- (z.B. "level_julian_gegner_4_besiegt").
		if game.quiz_win_value then
			game:set_value(game.quiz_win_value, true)
		end
		game.quiz_win_value = nil
		-- Back to NPC
		hero:unfreeze()
		hero:teleport(game.quiz_return_map, game.quiz_return_dest)
  elseif result == "exit" then
		game.quiz_win_value = nil
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
		local sprite = npc2:create_sprite(animation_set_id)
		-- Der Gegner steht still und schaut zum Helden
		-- (einige Gegner-Sprites starten sonst mit ihrer Lauf-Animation).
		if sprite:has_animation("stopped") then
			sprite:set_animation("stopped")
		end
		if sprite:get_num_directions() >= 4 then
			sprite:set_direction(3)
		end
	end
end
