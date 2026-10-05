--TODO: reimplement button mapping menu:
local language_menu = sol.modules.get_object("language_menu")
local common_config = require("scripts/menus/title_screen/common_config"):get_config()
common_config.options = {
  "sound",
  "fullscreen",
  "controls",
  "language",
  "credits",
  "back",
}

local menu = require("scripts/menus/title_screen/title_menu_factory").new(common_config)

local slider_factory = sol.modules.get_object("trilmenu_component_slider")
local slider_config = {
  x = 180, y = 144,
  size = {width = 108, height = 16},
  line_length = 100,
}
local sound_slider = slider_factory.create(slider_config)
slider_config.y = 160
local music_slider = slider_factory.create(slider_config)

function menu:process_selection(option)
  if option == "sound" then
    menu:switch_to_menu(require("scripts/menus/title_screen/sound"))

  elseif option == "fullscreen" then
    local is_fullscreen = sol.video.is_fullscreen()
    sol.video.set_fullscreen(not is_fullscreen)

  elseif option == "controls" then
    menu:switch_to_menu(require("scripts/menus/title_screen/controls"))

  elseif option == "language" then
    language_menu.force_choice = true --otherwise the menu will close itself if a language is already set
    sol.menu.start(menu, language_menu)
    function language_menu:on_finished()
      menu:update()
    end

  elseif option == "credits" then
    local credits_menu = sol.modules.get_object("credits_menu")
    sol.main.start_credits(function() sol.menu.stop(credits_menu) end)

  elseif option == "back" then
    menu:switch_to_menu(require("scripts/menus/title_screen/main_menu"))

  end
end

return menu
