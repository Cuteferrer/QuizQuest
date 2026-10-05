-- Main Lua script of the quest.
-- See the Lua API! http://www.solarus-games.org/doc/latest

require("scripts/features")
require("scripts/multi_events")
require("battle")

-- Edit scripts/menus/initial_menus_config.lua to add or change menus before starting a game.
local initial_menus_config = require("scripts/menus/initial_menus_config")
local initial_menus = {}

-- This function is called when Solarus starts.
function sol.main:on_started()

	sol.main.load_settings()
	math.randomseed(os.time())

	-- Логотип (PNG) перед стартовыми меню.
	local logo_menu = {}
	local logo = sol.surface.load("sprites/menus/quizquest.png")   -- путь от data/
	local LOGO_FILL = 0.8   -- доля экрана под логотип (0..1); 1 = впритык к краям

	function logo_menu:on_started()
		-- Держим 2 секунды, затем плавно гасим и закрываем.
		sol.timer.start(logo_menu, 2000, function()
			logo:fade_out(20, function()
				sol.menu.stop(logo_menu)
			end)
		end)
	end

	function logo_menu:on_draw(screen)
		local w, h = screen:get_size()
		local lw, lh = logo:get_size()
		local scale = math.min(w / lw, h / lh) * LOGO_FILL   -- вписать целиком, пропорции сохранены
		logo:set_scale(scale, scale)
		logo:draw(screen, (w - lw * scale) / 2, (h - lh * scale) / 2)   -- по центру
	end

	function logo_menu:on_key_pressed(key)
		sol.menu.stop(logo_menu)   -- пропуск любой клавишей
		return true
	end

	-- Собираем стартовые меню из конфига и связываем их по цепочке.
	for _, menu_script in ipairs(initial_menus_config) do
		initial_menus[#initial_menus + 1] = require(menu_script)
	end

	for i, menu in ipairs(initial_menus) do
		function menu:on_finished()
			if sol.main.get_game() ~= nil then
				-- Игра уже запущена (например, быстрый старт отладочной клавишей).
				return
			end
			local next_menu = initial_menus[i + 1]
			if next_menu ~= nil then
				sol.menu.start(sol.main, next_menu)
			end
		end
	end

	-- Когда логотип закрылся — запускаем первое стартовое меню (если есть).
	function logo_menu:on_finished()
		if sol.main.get_game() ~= nil then
			return
		end
		if initial_menus[1] ~= nil then
			sol.menu.start(sol.main, initial_menus[1])
		end
	end

	-- Показываем логотип первым.
	sol.menu.start(sol.main, logo_menu)

	local game_meta = sol.main.get_metatable("game")
	game_meta:register_event("on_started", function(game)
		-- При старте игры гасим логотип и стартовые меню.
		sol.menu.stop(logo_menu)
		for _, menu in ipairs(initial_menus) do
			sol.menu.stop(menu)
		end
	end)
end

-- Event called when the program stops.
function sol.main:on_finished()

	sol.main.save_settings()
end

-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)

	local handled = false
	if key == "f11" or
			(key == "return" and (modifiers.alt or modifiers.control)) then
		-- F11 or Ctrl + return or Alt + Return: switch fullscreen.
		sol.video.set_fullscreen(not sol.video.is_fullscreen())
		handled = true
	elseif key == "f4" and modifiers.alt then
		-- Alt + F4: stop the program.
		sol.main.exit()
		handled = true
	elseif key == "escape" and sol.main.get_game() == nil then
		-- Escape in pre-game menus: stop the program.
		sol.main.exit()
		handled = true
	end

	return handled
end