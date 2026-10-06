-- scripts/quiz_menu.lua
-- quiz_menu.start(context, ids, npc_sprite_id, on_finished)
--   ids: { "AE2_UML_Q001", ... } — какие вопросы и в каком порядке.
--   on_finished(result, score): result = "win" | "lose".

local json = require("scripts/json")

local quiz_menu = {}

local FONT = "enter_command"                     
local QUESTIONS_FILE = "questions/fragen.json"
local IMAGE_DIR = "images/"                 -- media.src -> images/<src>.png

local PROMPT_X, PROMPT_Y        = 16, 12
local PROMPT_IMG_W, PROMPT_IMG_H = 96, 50
local OPT_X, OPT_Y0, OPT_STEP   = 16, 110, 20
local BOX                       = 8      -- checkbox size
local NPC_X, NPC_Y              = 270, 160
local ENEMY_HEARTS_X, ENEMY_HEARTS_Y   = 244, 96
local PLAYER_HEARTS_X, PLAYER_HEARTS_Y = 10, 10
local HEART                     = 10
local PROMPT_W = 288

-- questions load
local questions_by_id = nil
local function load_index()
	if questions_by_id then return questions_by_id end
	local f, err = sol.file.open(QUESTIONS_FILE)
	if not f then error("Не открыть " .. QUESTIONS_FILE .. ": " .. tostring(err)) end
	local content = f:read("*a")
	f:close()
	content = content:gsub("^\239\187\191", "")  
	questions_by_id = {}
	for _, q in ipairs(json.decode(content)) do
		questions_by_id[q.id] = q
	end
	return questions_by_id
end

local function wrap(text, font, size, max_width)
	local lines = {}
	for paragraph in (text .. "\n"):gmatch("(.-)\n") do  
		local line = ""
		for word in paragraph:gmatch("%S+") do
			local candidate = (line == "") and word or (line .. " " .. word)
			local w = sol.text_surface.get_predicted_size(font, size, candidate)
			if w <= max_width or line == "" then
				line = candidate
			else
				lines[#lines + 1] = line
				line = word
			end
		end
		lines[#lines + 1] = line
	end
	return lines
end

local function sets_equal(a, b)
	for k in pairs(a) do if not b[k] then return false end end
	for k in pairs(b) do if not a[k] then return false end end
	return true
end

function quiz_menu.start(context, ids, npc_sprite_id, on_finished)
	local index = load_index()

	local questions = {}
	for _, id in ipairs(ids) do
		if index[id] then
			questions[#questions + 1] = index[id]
		else
			print("quiz: нет вопроса с id " .. tostring(id))
		end
	end
	if #questions == 0 then return end

	local menu = {}
	local q_index = 1
	local cursor = 1
	local num_options = 1
	local marked = {}            -- marked[i] = true
  local prompt_lines = {}
	local correct_set = {}       -- correct_set[i] = true for current question
	local current_image = nil
	local player_lives = 3
	local enemy_lives = #questions
	local score = 0
	local last_scale = nil

	local npc_sprite = npc_sprite_id and sol.sprite.create(npc_sprite_id) or nil

  local heart_full = sol.sprite.create("hud/heart")
  local heart_empty = sol.sprite.create("hud/empty_heart")

	local prompt_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
	local option_texts = {}
	local function option_text(i)
		if not option_texts[i] then
			option_texts[i] = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
			if last_scale then option_texts[i]:set_font_size(math.floor(14 * last_scale)) end
		end
		return option_texts[i]
	end

	local image_cache = {}
	local function get_image(path)
		if not path then return nil end
		if image_cache[path] == nil then
			local ok, surf = pcall(sol.surface.load, path)
			image_cache[path] = ok and surf or false
		end
		return image_cache[path] or nil
	end

	local function load_question()
		local q = questions[q_index]
		num_options = #q.options
		prompt_text:set_text(q.question or "")
    prompt_lines = wrap(q.question or "", FONT, 16, PROMPT_W)
		for i = 1, num_options do
			option_text(i):set_text(q.options[i].text or "")
		end
		local correct_ids = {}
		for _, cid in ipairs(q.correct_answers) do correct_ids[cid] = true end
		correct_set = {}
		for i = 1, num_options do
			if correct_ids[q.options[i].id] then correct_set[i] = true end
		end
		current_image = q.media and q.media.src and get_image(IMAGE_DIR .. q.media.src .. ".png") or nil
		marked = {}
		cursor = 1
	end

	local function confirm()
		if sets_equal(marked, correct_set) then
			score = score + 1
			enemy_lives = enemy_lives - 1
			if enemy_lives <= 0 then
				menu.result = "win"
				sol.menu.stop(menu)
			else
				q_index = q_index + 1
				load_question()
			end
		else
			player_lives = player_lives - 1
			marked = {}
			if player_lives <= 0 then
				menu.result = "lose"
				sol.menu.stop(menu)
			end
		end
	end

	local previous_video_draw = sol.video.on_draw

	local function draw_image(screen, surface, qx, qy, box_w, box_h, scale)
		if not surface then return end
		local sw, sh = surface:get_size()
		surface:set_scale(box_w * scale / sw, box_h * scale / sh)
		surface:draw(screen, qx * scale, qy * scale)
	end

local function draw_hearts(screen, full_count, total, qx, qy, scale)
	local hw = heart_full:get_size()
	for i = 1, total do
		local s = (i <= full_count) and heart_full or heart_empty
		local ox, oy = s:get_origin()        -- origin
		s:set_scale(scale, scale)
		local tx = (qx + (i - 1) * (hw + 2)) * scale
		local ty = qy * scale
		s:draw(screen, tx + ox * scale, ty + oy * scale)
	end

end
	function menu:on_started()
		load_question()
	end

	function menu:on_key_released(command)
		if command == "up" then
			cursor = (cursor - 2) % num_options + 1
			return true
		elseif command == "down" then
			cursor = cursor % num_options + 1
			return true
  		elseif command == "space" then
			marked[cursor] = (not marked[cursor]) or nil   -- Check / Uncheck
			return true
		elseif command == "return" then
			confirm()
			return true
    elseif command == "escape" then
     menu.result = "exit"
			sol.menu.stop(menu)
      return false
		end
		return false
	end

	function menu:on_finished()
		sol.video.on_draw = previous_video_draw
		if on_finished then on_finished(menu.result or "lose", score) end
	end

	function sol.video:on_draw(screen)
		local qw, qh = sol.video.get_quest_size()
		local ww, wh = sol.video.get_window_size()
		local scale = wh / qh

		if scale ~= last_scale then
			prompt_text:set_font_size(math.floor(16 * scale))
			for i = 1, num_options do
				option_text(i):set_font_size(math.floor(14 * scale))
			end
			last_scale = scale
		end

		screen:fill_color({0, 0, 0, 150})

		draw_image(screen, current_image, PROMPT_X, PROMPT_Y, PROMPT_IMG_W, PROMPT_IMG_H, scale)
		local line_h = 18  
		local ty = PROMPT_Y + PROMPT_IMG_H + 6
		for _, line in ipairs(prompt_lines) do
			prompt_text:set_text(line)
			prompt_text:draw(screen, PROMPT_X * scale, ty * scale)
			ty = ty + line_h
		end

		for i = 1, num_options do
			local oy = OPT_Y0 + (i - 1) * OPT_STEP
			local box_color = marked[i] and {255, 220, 60} or {90, 90, 90}
			screen:fill_color(box_color, OPT_X * scale, oy * scale, BOX * scale, BOX * scale)
			local t = option_text(i)
			t:set_color(i == cursor and {255, 255, 0} or {255, 255, 255})
			t:draw(screen, (OPT_X + BOX + 6) * scale, (oy + BOX / 2) * scale)
		end

		if npc_sprite then
			npc_sprite:set_scale(scale, scale)
			npc_sprite:draw(screen, NPC_X * scale, NPC_Y * scale)
		end

		draw_hearts(screen, enemy_lives, #questions, ENEMY_HEARTS_X, ENEMY_HEARTS_Y, scale)
		draw_hearts(screen, player_lives, 3, PLAYER_HEARTS_X, PLAYER_HEARTS_Y, scale)
	end

	sol.menu.start(context, menu)
	return menu
end

return quiz_menu