-- scripts/quiz_menu.lua
-- quiz_menu.start(context, ids, npc_sprite_id, on_finished)
--   ids: { "AE2_UML_Q001", ... }.
--   on_finished(result, score): result = "win" | "lose".

local json = require("scripts/json")

local quiz_menu = {}

local FONT = "enter_command"                     
local QUESTIONS_FILES = {
	"questions/AE2_UML_Fragen.json",
	"questions/AE2_ENTWICKLUNG_Fragen.json",
	"questions/AE2_PM_Fragen.json",
	"questions/AE2_WISO_Fragen.json",
}
local IMAGE_DIR = "images/"                 -- Bild zur Frage: images/<Fragen-ID>.png

local PROMPT_X, PROMPT_Y        = 16, 12
local PROMPT_IMG_W, PROMPT_IMG_H = 96, 50
-- Layout, wenn die Frage ein Bild hat: Bild oben rechts, Fragetext links daneben.
local IMG_X, IMG_Y, IMG_W, IMG_H = 196, 8, 116, 70   -- darunter: Hinweis, dann Gegner-Herzen (y=96)
local IMG_PROMPT_Y, IMG_PROMPT_W = 28, 172
-- Vergroesserte Ansicht (Taste Tab)
local ZOOM_X, ZOOM_Y, ZOOM_W, ZOOM_H = 8, 8, 304, 210
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
	questions_by_id = {}
	for _, path in ipairs(QUESTIONS_FILES) do
		local f, err = sol.file.open(path)
		if not f then error("Unable to open " .. path .. ": " .. tostring(err)) end
		local content = f:read("*a")
		f:close()
		content = content:gsub("^\239\187\191", "")
		for _, q in ipairs(json.decode(content)) do
			questions_by_id[q.id] = q
		end
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

function quiz_menu.start(context, ids, npc_sprite_id, on_finished, file_id)
	local index = load_index()

	local questions = {}
	for _, id in ipairs(ids) do
		if index[id] then
			questions[#questions + 1] = index[id]
		else
			print("quiz: no question found, id:" .. tostring(id))
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
	local image_zoomed = false
	local player_lives = 3
	local enemy_lives = #questions
	local score = 0
	local last_scale = nil

	local npc_sprite = npc_sprite_id and sol.sprite.create(npc_sprite_id) or nil

  local heart_full = sol.sprite.create("hud/heart")
  local heart_empty = sol.sprite.create("hud/empty_heart")

	local prompt_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
	local hint_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
	local option_texts = {}
	local function option_text(i)
		if not option_texts[i] then
			option_texts[i] = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
			if last_scale then option_texts[i]:set_font_size(math.floor(14 * last_scale)) end
		end
		return option_texts[i]
	end

	local image_cache = {}
	-- Laedt images/<Fragen-ID>.png, falls vorhanden (sonst nil).
	local function get_image(path)
		if not path then return nil end
		if image_cache[path] == nil then
			local surf = false
			if sol.file.exists(path) then
				local ok, s = pcall(sol.surface.load, path)
				if ok and s then
					surf = s
				else
					print("quiz: Bild konnte nicht geladen werden: " .. path)
				end
			end
			image_cache[path] = surf
		end
		return image_cache[path] or nil
	end

	local function load_question()
		local q = questions[q_index]
		num_options = #q.options
		prompt_text:set_text(q.question or "")
		current_image = get_image(IMAGE_DIR .. q.id .. ".png")
		image_zoomed = false
		prompt_lines = wrap(q.question or "", FONT, 16, current_image and IMG_PROMPT_W or PROMPT_W)
		for i = 1, num_options do
			option_text(i):set_text(q.options[i].text or "")
		end
		local correct_ids = {}
		for _, cid in ipairs(q.correct_answers) do correct_ids[cid] = true end
		correct_set = {}
		for i = 1, num_options do
			if correct_ids[q.options[i].id] then correct_set[i] = true end
		end
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

	-- Zeichnet das Bild in die Box (seitenverhaeltnistreu, zentriert).
	local function draw_image(screen, surface, qx, qy, box_w, box_h, scale)
		if not surface then return end
		local sw, sh = surface:get_size()
		local fit = math.min(box_w / sw, box_h / sh)
		local dw, dh = sw * fit, sh * fit
		local dx, dy = qx + (box_w - dw) / 2, qy + (box_h - dh) / 2
		screen:fill_color({255, 255, 255}, math.floor((dx - 1) * scale), math.floor((dy - 1) * scale),
			math.ceil((dw + 2) * scale), math.ceil((dh + 2) * scale))
		surface:set_scale(fit * scale, fit * scale)
		surface:draw(screen, math.floor(dx * scale), math.floor(dy * scale))
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

	-- Wichtig: Tasten werden beim DRUECKEN ausgewertet und sowohl Druecken als auch
	-- Loslassen werden komplett verschluckt (return true). Vorher wurde nur das
	-- Loslassen abgefangen: das Druecken (z.B. Pfeil hoch/runter) kam beim Spiel an,
	-- das Loslassen aber nie -> nach der Rueckkehr lief der Held endlos weiter.
	function menu:on_key_pressed(command)
		-- Bild vergroessern / verkleinern
		if current_image and command == "tab" then
			image_zoomed = not image_zoomed
			return true
		end
		if image_zoomed then
			if command == "escape" or command == "return" or command == "space" then
				image_zoomed = false
			end
			return true
		end
		if command == "up" then
			cursor = (cursor - 2) % num_options + 1
		elseif command == "down" then
			cursor = cursor % num_options + 1
		elseif command == "space" then
			marked[cursor] = (not marked[cursor]) or nil   -- Check / Uncheck
		elseif command == "return" then
			confirm()
		elseif command == "escape" then
			menu.result = "exit"
			sol.menu.stop(menu)
		end
		return true
	end

	function menu:on_key_released(command)
		return true
	end

	function menu:on_joypad_button_pressed() return true end
	function menu:on_joypad_button_released() return true end
	function menu:on_joypad_axis_moved() return true end
	function menu:on_joypad_hat_moved() return true end

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
			hint_text:set_font_size(math.floor(10 * scale))
			last_scale = scale
		end

		screen:fill_color({0, 0, 0, 150})

		-- Vergroesserte Bildansicht
		if current_image and image_zoomed then
			screen:fill_color({0, 0, 0, 220})
			draw_image(screen, current_image, ZOOM_X, ZOOM_Y, ZOOM_W, ZOOM_H, scale)
			hint_text:set_text("[Tab] zurueck zur Frage")
			hint_text:draw(screen, ZOOM_X * scale, (ZOOM_Y + ZOOM_H + 10) * scale)
			return
		end

		local line_h = 18
		local ty = PROMPT_Y + PROMPT_IMG_H + 6
		if current_image then
			draw_image(screen, current_image, IMG_X, IMG_Y, IMG_W, IMG_H, scale)
			hint_text:set_text("[Tab] Bild vergroessern")
			hint_text:draw(screen, IMG_X * scale, (IMG_Y + IMG_H + 6) * scale)
			ty = IMG_PROMPT_Y
		end
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