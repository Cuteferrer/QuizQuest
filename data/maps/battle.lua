local map = ...
local game = map:get_game()
local quiz_menu = require("scripts/quiz_menu")

local quiz_ids = { "AE2_UML_Q001", "AE2_UML_Q002", "AE2_UML_Q003", "AE2_UML_Q008" }

local function start_quiz()
	local hero = map:get_hero()
	hero:freeze()
	quiz_menu.start(map, quiz_ids, game.shared_npc_animation_set, function(result, score)
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
