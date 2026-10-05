local menu = {}

--TODO: Implement something like this as a pre-menu to the main menu maybe?
local press_button_prompt = sol.text_surface.create{
  font = "enter_command",
  text_key = "menu.title_screen.press_any_button",
  font_size = 16,
  horizontal_alignment = "center"
}
press_button_prompt:set_opacity(0)


function menu:on_started()
  sol.timer.start(menu, 8000, function()
    press_button_prompt:fade_in()
  end)
end


function menu:on_key_pressed()
  menu:process_input()
  return true
end

function menu:on_joypad_button_pressed()
  menu:process_input()
  return true
end


function menu:process_input()
  --local new_menu = require("scripts/menus/title_screen/initial_setup_questions")
  local new_menu = require("scripts/menus/title_screen/main_menu")
  local top_menu = menu.top_menu
  sol.audio.play_sound"drum_low"
  top_menu:set_current_submenu(new_menu)
  sol.menu.start(top_menu, new_menu)
  sol.menu.stop(menu)
  return true
end


function menu:on_draw(dst)
  press_button_prompt:draw(dst, 208, 150)
end



return menu