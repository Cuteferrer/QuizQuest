-- scripts/quiz_menu.lua
-- quiz_menu.start(context, ids, npc_sprite_id, on_finished, options)
--   ids: { "AE2_UML_Q001", ... } — welche Fragen, in welcher Reihenfolge.
--   on_finished(result, score): result = "win" | "lose" | "exit" | "timeout".
--   options (optional):
--     time_limit = Sekunden  -> Countdown oben in der Mitte; bei 0 endet das
--                               Quiz mit result = "timeout".
--     boss = true            -> rotes "BOSS"-Label ueber dem Gegner.
--
-- Fullscreen-Unterstuetzung: Die Ausgabegroesse kommt aus screen:get_size(),
-- denn sol.video.get_window_size() liefert im Vollbildmodus NICHT die echte
-- Aufloesung (Doku: sie gibt die Groesse fuer die Rueckkehr in den
-- Fenstermodus zurueck). Gezeichnet wird direkt auf den Screen in realen
-- Pixeln (scharfer Text), mit derselben Skalierung+Zentrierung wie die
-- Engine im Letter-Boxing-Modus.

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
-- Layout mit Bild: Bild oben rechts, Fragetext links daneben.
local IMG_X, IMG_Y, IMG_W, IMG_H = 196, 8, 116, 70   -- darunter: Hinweis, dann Gegner-Herzen (y=96)
local IMG_PROMPT_Y, IMG_PROMPT_W = 28, 172
-- Vergroesserte Ansicht (Taste Tab)
local ZOOM_X, ZOOM_Y, ZOOM_W, ZOOM_H = 8, 8, 304, 210
local OPT_X, OPT_Y0, OPT_STEP   = 16, 110, 20
local BOX                       = 8      -- Checkbox-Groesse
-- Antworten werden automatisch umgebrochen (wie der Fragetext):
local OPT_TEXT_X                = OPT_X + BOX + 6   -- Textanfang rechts neben der Checkbox
local OPT_RIGHT                 = 240               -- rechter Rand (rechts davon: Gegner + Herzen)
local OPT_W                     = OPT_RIGHT - OPT_TEXT_X
local OPT_GAP                   = 4                 -- Abstand zwischen zwei Antworten
local OPT_BOTTOM                = 236               -- unterster nutzbarer Punkt
local OPT_FONT_SIZES            = { 14, 12, 10 }    -- wird kleiner, wenn es sonst nicht passt
local PROMPT_FONT_SIZES         = { 16, 14, 12, 10 } -- dito fuer den Fragetext
local NPC_X, NPC_Y              = 270, 160
local ENEMY_HEARTS_X, ENEMY_HEARTS_Y   = 244, 96
local PLAYER_HEARTS_X, PLAYER_HEARTS_Y = 10, 10
local HEART                     = 10
local PROMPT_W = 288
local TIMER_X, TIMER_Y          = 160, 10     -- Bosstimer (zentriert)
local TIMER_WARN                = 10          -- ab hier rot
local BOSS_LABEL_Y              = 122         -- ueber dem Gegner-Sprite (NPC_X)

local FONT_SIZE_PROMPT = 16
local FONT_SIZE_OPTION = 14
local FONT_SIZE_HINT   = 10
local FONT_SIZE_TIMER  = 14
local FONT_SIZE_BOSS   = 12
local LINE_H = 18

-- Fragen laden
local questions_by_id = nil
local function load_index()
	if questions_by_id then return questions_by_id end
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

function quiz_menu.start(context, ids, npc_sprite_id, on_finished, options)
	options = options or {}
	local index = load_index()

	local questions = {}
	for _, id in ipairs(ids) do
		if index[id] then
			questions[#questions + 1] = index[id]
		else
			print("quiz: keine Frage mit id " .. tostring(id))
		end
	end
	if #questions == 0 then return end

	local menu = {}
	local q_index = 1
	local cursor = 1
	local num_options = 1
	local marked = {}            -- marked[i] = true
	local prompt_lines = {}
	local option_lines = {}      -- option_lines[i] = { "Zeile 1", "Zeile 2", ... }
	local opt_font_size = FONT_SIZE_OPTION
	local opt_line_h = FONT_SIZE_OPTION + 3
	local opt_y0 = OPT_Y0
	local prompt_font_size = FONT_SIZE_PROMPT
	local prompt_line_h = LINE_H
	local prompt_y0 = PROMPT_Y + PROMPT_IMG_H + 6
	local applied_prompt_font = nil
	local applied_opt_font = nil -- zuletzt gesetzte (skalierte) Schriftgroesse der Antworten
	local correct_set = {}       -- correct_set[i] = true fuer die aktuelle Frage
	local current_image = nil
	local image_zoomed = false
	local player_lives = 3
	local enemy_lives = #questions
	local score = 0
	local last_scale = nil
	local time_left = options.time_limit      -- nil = kein Timer

	-- Aktueller Massstab + Versatz der Questflaeche im Fenster (Letterbox).
	-- Wird in on_draw aus screen:get_size() ermittelt.
	local view_scale, view_ox, view_oy = 1, 0, 0

	local function sx(x) return math.floor(view_ox + x * view_scale) end
	local function sy(y) return math.floor(view_oy + y * view_scale) end
	local function ss(v) return v * view_scale end

	local npc_sprite = npc_sprite_id and sol.sprite.create(npc_sprite_id) or nil

	local heart_full = sol.sprite.create("hud/heart")
	local heart_empty = sol.sprite.create("hud/empty_heart")

	local prompt_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
	local hint_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
	local timer_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "center" }
	local boss_text = sol.text_surface.create{ font = FONT, horizontal_alignment = "center", text = "BOSS" }
	boss_text:set_color({255, 40, 40})
	local option_texts = {}
	local function option_text(i)
		if not option_texts[i] then
			option_texts[i] = sol.text_surface.create{ font = FONT, horizontal_alignment = "left" }
			if applied_opt_font then option_texts[i]:set_font_size(applied_opt_font) end
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
		-- Layout: Frage umbrechen, Antworten darunter umbrechen. Passt alles
		-- zusammen nicht bis OPT_BOTTOM, wird zuerst die Antwortschrift und
		-- danach die Frageschrift schrittweise kleiner.
		-- Reicht auch die kleinste Schrift nicht, wird im zweiten Durchlauf
		-- (compact) der freie Platz oben genutzt: Frage startet hoeher und die
		-- Antworten duerfen direkt unter der Frage beginnen (ohne Bild).
		local prompt_w = current_image and IMG_PROMPT_W or PROMPT_W
		local fits = false
		for _, compact in ipairs({ false, true }) do
		prompt_y0 = (current_image or compact) and IMG_PROMPT_Y or (PROMPT_Y + PROMPT_IMG_H + 6)
		local min_opt_y = (compact and not current_image) and 0 or OPT_Y0
		for _, psize in ipairs(PROMPT_FONT_SIZES) do
			local plines = wrap(q.question or "", FONT, psize, prompt_w)
			local plh = psize + 2
			local prompt_bottom = prompt_y0 + (#plines - 1) * plh + plh / 2
			local y0 = math.max(min_opt_y, math.ceil(prompt_bottom + 8))
			for _, size in ipairs(OPT_FONT_SIZES) do
				local line_h = size + 3
				local lines = {}
				local y = y0
				for i = 1, num_options do
					lines[i] = wrap(q.options[i].text or "", FONT, size, OPT_W)
					y = y + #lines[i] * line_h + OPT_GAP
				end
				prompt_lines, prompt_font_size, prompt_line_h = plines, psize, plh
				option_lines, opt_font_size, opt_line_h, opt_y0 = lines, size, line_h, y0
				if y - OPT_GAP <= OPT_BOTTOM then fits = true break end
			end
			if fits then break end
		end
		if fits then break end
		end
		if not fits then
			print("quiz: Frage " .. tostring(q.id) .. " ist auch mit kleinster Schrift zu lang")
		end
		for i = 1, num_options do
			option_text(i)
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
	local function draw_image(screen, surface, qx, qy, box_w, box_h)
		if not surface then return end
		local sw, sh = surface:get_size()
		local fit = math.min(box_w / sw, box_h / sh)
		local dw, dh = sw * fit, sh * fit
		local dx, dy = qx + (box_w - dw) / 2, qy + (box_h - dh) / 2
		screen:fill_color({255, 255, 255}, sx(dx) - 1, sy(dy) - 1,
			math.ceil(ss(dw)) + 2, math.ceil(ss(dh)) + 2)
		surface:set_scale(fit * view_scale, fit * view_scale)
		surface:draw(screen, sx(dx), sy(dy))
	end

	local function draw_hearts(screen, full_count, total, qx, qy)
		local hw = heart_full:get_size()
		for i = 1, total do
			local s = (i <= full_count) and heart_full or heart_empty
			local ox, oy = s:get_origin()
			s:set_scale(view_scale, view_scale)
			s:draw(screen, sx(qx + (i - 1) * (hw + 2)) + ss(ox), sy(qy) + ss(oy))
		end
	end

	function menu:on_started()
		load_question()
		if time_left then
			-- Laeuft auch weiter, wenn ein Bild per Tab vergroessert ist.
			-- Haengt am Menue und endet daher automatisch mit dem Quiz.
			sol.timer.start(menu, 1000, function()
				time_left = time_left - 1
				if time_left <= 0 then
					time_left = 0
					menu.result = "timeout"
					sol.menu.stop(menu)
					return false
				end
				return true
			end)
		end
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
			marked[cursor] = (not marked[cursor]) or nil   -- ankreuzen / abwaehlen
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

	-- Hinweis: Die folgenden Helfer stehen bewusst AUSSERHALB von on_draw.
	-- Solarus nutzt LuaJIT, und dort darf eine Funktion hoechstens 60 Upvalues
	-- (Variablen von ausserhalb der Funktion) verwenden. Sonst laedt die Datei nicht.

	-- Schriftgroessen von Frage und Antworten (haengen von Skalierung UND Textlaenge ab)
	local function update_fonts(scale)
		local wanted = math.floor(opt_font_size * scale)
		if wanted ~= applied_opt_font then
			applied_opt_font = wanted
			for _, t in pairs(option_texts) do t:set_font_size(wanted) end
		end
		local wanted_prompt = math.floor(prompt_font_size * scale)
		if wanted_prompt ~= applied_prompt_font then
			applied_prompt_font = wanted_prompt
			prompt_text:set_font_size(wanted_prompt)
		end
	end

	-- Antworten mit Checkbox, zeilenweise umgebrochen
	local function draw_options(screen)
		local oy = opt_y0
		for i = 1, num_options do
			local box_color = marked[i] and {255, 220, 60} or {90, 90, 90}
			screen:fill_color(box_color, sx(OPT_X), sy(oy), ss(BOX), ss(BOX))
			local t = option_text(i)
			t:set_color(i == cursor and {255, 255, 0} or {255, 255, 255})
			for _, line in ipairs(option_lines[i] or {}) do
				t:set_text(line)
				t:draw(screen, sx(OPT_TEXT_X), sy(oy + BOX / 2))
				oy = oy + opt_line_h
			end
			oy = oy + OPT_GAP
		end
	end

	-- Bosstimer (auch in der vergroesserten Bildansicht sichtbar)
	local function draw_timer(screen)
		if not time_left then return end
		timer_text:set_text(string.format("Zeit %d:%02d", math.floor(time_left / 60), time_left % 60))
		timer_text:set_color(time_left <= TIMER_WARN and {255, 60, 60} or {255, 255, 255})
		timer_text:draw(screen, sx(TIMER_X), sy(TIMER_Y))
	end

	function sol.video:on_draw(screen)
		-- Echte Ausgabegroesse holen: 1 Pixel von "screen" = 1 Pixel auf dem
		-- Monitor, auch im Vollbildmodus (siehe Doku zu sol.video:on_draw).
		local out_w, out_h = screen:get_size()
		local qw, qh = sol.video.get_quest_size()

		-- Gleiche Transformation wie die Engine im Letter-Boxing-Modus.
		local new_scale = math.min(out_w / qw, out_h / qh)
		view_scale = new_scale
		view_ox = math.floor((out_w - qw * new_scale) / 2)
		view_oy = math.floor((out_h - qh * new_scale) / 2)

		if new_scale ~= last_scale then
			hint_text:set_font_size(math.floor(FONT_SIZE_HINT * new_scale))
			timer_text:set_font_size(math.floor(FONT_SIZE_TIMER * new_scale))
			boss_text:set_font_size(math.floor(FONT_SIZE_BOSS * new_scale))
			last_scale = new_scale
		end
		update_fonts(new_scale)

		-- Abdunkeln der gesamten Ausgabe (auch der Letterbox-Raender).
		screen:fill_color({0, 0, 0, 150})

		-- Vergroesserte Bildansicht
		if current_image and image_zoomed then
			screen:fill_color({0, 0, 0, 220})
			draw_image(screen, current_image, ZOOM_X, ZOOM_Y, ZOOM_W, ZOOM_H)
			hint_text:set_text("[Tab] zurueck zur Frage")
			hint_text:draw(screen, sx(ZOOM_X), sy(ZOOM_Y + ZOOM_H + 10))
			draw_timer(screen)
			return
		end

		local ty = prompt_y0
		if current_image then
			draw_image(screen, current_image, IMG_X, IMG_Y, IMG_W, IMG_H)
			hint_text:set_text("[Tab] Bild vergroessern")
			hint_text:draw(screen, sx(IMG_X), sy(IMG_Y + IMG_H + 6))
		end
		for _, line in ipairs(prompt_lines) do
			prompt_text:set_text(line)
			prompt_text:draw(screen, sx(PROMPT_X), sy(ty))
			ty = ty + prompt_line_h
		end

		draw_options(screen)

		if npc_sprite then
			npc_sprite:set_scale(view_scale, view_scale)
			npc_sprite:draw(screen, sx(NPC_X), sy(NPC_Y))
		end

		if options.boss then
			boss_text:draw(screen, sx(NPC_X), sy(BOSS_LABEL_Y))
		end

		draw_hearts(screen, enemy_lives, #questions, ENEMY_HEARTS_X, ENEMY_HEARTS_Y)
		draw_hearts(screen, player_lives, 3, PLAYER_HEARTS_X, PLAYER_HEARTS_Y)
		draw_timer(screen)
	end

	sol.menu.start(context, menu)
	return menu
end

return quiz_menu