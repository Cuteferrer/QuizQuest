local confirm_menu = require("scripts/menus/title_screen/confirm")
local file_select_menu = require("scripts/menus/title_screen/file_select")
local load_game_menu = require("scripts/menus/title_screen/load_game")
local settings = sol.modules.get_object("settings_manager")
local common_config = require("scripts/menus/title_screen/common_config"):get_config()
local main_options = require("scripts/menus/title_screen/main_menu_options").get_options()

local save_filename = settings.get_value("last_loaded_savefile") or "save1.dat"

common_config.options = main_options
local menu = require("scripts/menus/title_screen/title_menu_factory").new(common_config)

file_select_menu.parent_menu = menu

local function load_game(filename)
  load_game_menu:set_filename(filename)
  menu.process_selection = function() end --remove processing so we can't start multiple games at once TODO: why is that possible even????
  sol.menu.start(sol.main, load_game_menu)
end


function menu:process_selection(option)
  if menu.load_game_freeze then
    --While file select is loading a new game, we can't try to open file select again and double-load the game
    return
  elseif option == "continue" then
    if menu.previous_save_exists then
      load_game(save_filename)
    else
      sol.audio.play_sound("wrong")
    end
  elseif option == "load" then
    if menu.any_saves_exist then
      file_select_menu:set_mode("load")
      sol.menu.start(sol.main, file_select_menu)
    else
      sol.audio.play_sound("wrong")
    end
  elseif option == "new_game" then
    file_select_menu:set_mode("new_game")
    sol.menu.start(sol.main, file_select_menu)
  elseif option == "options" then
    menu:switch_to_menu(require("scripts/menus/title_screen/options"))
  elseif option == "wishlist" then
    sol.main.open_steam_page()
  elseif option == "quit" then
    sol.main.exit()
  end
end

function menu:on_started()
  menu.load_game_freeze = nil
  menu.previous_save_exists = sol.game.exists(save_filename)
  menu.any_saves_exist = file_select_menu:do_any_saves_exist()
  if not menu.previous_save_exists then
    menu:set_option_color("continue", sol.colors.ui_grey_med)
    menu:set_cursor_index(3)
  else
    menu:set_option_color("continue", {255,255,255})
  end
  if not menu.any_saves_exist then
    menu:set_option_color("load", sol.colors.ui_grey_med)
  end
end


return menu
