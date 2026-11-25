local map = ...
local game = map:get_game()
local quiz_menu = require("scripts/quiz_menu")

local quiz_ids = { "AE2_UML_Q001", "AE2_UML_Q002", "AE2_UML_Q003", "AE2_UML_Q008" }

local function start_quiz()
	local hero = map:get_hero()
	hero:freeze()
	-- An NPC can choose its own questions via game.quiz_ids (e.g. Level 4 hallways).
	local ids = game.quiz_ids or quiz_ids
	quiz_menu.start(map, ids, game.shared_npc_animation_set, function(result, score)
	if result == "win" then
		-- Remember the victory if the NPC asked for it (e.g. "level4_flur1_done").
		if game.quiz_win_value then
			game:set_value(game.quiz_win_value, true)
		end
		game.quiz_ids = nil
		game.quiz_win_value = nil
		-- Back to NPC
		hero:unfreeze()
		hero:teleport(game.quiz_return_map, game.quiz_return_dest)
  elseif result == "exit" then
		game.quiz_ids = nil
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
		npc2:create_sprite(animation_set_id)
	end
end
