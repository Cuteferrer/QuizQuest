--TODO: reimplement button mapping menu:
local common_config = require("scripts/menus/title_screen/common_config"):get_config()
common_config.options = {
  "sound_volume",
  "music_volume",
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
  if option == "sound_volume" then
    sound_slider:set_position(sol.audio.get_sound_volume()) --set the slider's initial position
    function sound_slider:process_change(new_level)
      sol.audio.set_sound_volume(new_level)
      sol.audio.play_sound"cursor"
    end
    sol.menu.start(menu, sound_slider)

  elseif option == "music_volume" then
    music_slider:set_position(sol.audio.get_music_volume()) --set the slider's initial position
    function music_slider:process_change(new_level)
      sol.audio.set_music_volume(new_level)
      sol.audio.play_sound"cursor"
    end
    sol.menu.start(menu, music_slider)

  elseif option == "back" then
    menu:switch_to_menu(require("scripts/menus/title_screen/options"))

  end
end

return menu
