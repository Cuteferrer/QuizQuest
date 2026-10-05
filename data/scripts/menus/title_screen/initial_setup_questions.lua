--[[
Created by Max Mraz, licensed MIT

Can ask a series of questions to set up some initial config stuff for player preference
--]]

local settings = sol.modules.get_object("settings_manager")
local controls_manager = sol.controls.get_controls_manager()
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()
local screen_width, screen_height = sol.video.get_quest_size()
local menu = {}
local ox, oy = screen_width / 2, 120

local questions = {
  {
    prompt_key = "menu.title_screen.initial_questions.keyboard_style.question",
    options = {
      {key = "menu.title_screen.initial_questions.keyboard_style.kbm"},
      {key = "menu.title_screen.initial_questions.keyboard_style.keyboard"},
    },
  },
}

local current_question = 1
local cursor_index = 1
local prompt_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
  horizontal_alignment = "center"
}
local options_surfaces = {}



function menu:on_started()
  if settings.get_value("initial_setup_questions_asked") then
    menu:finish()
  else
    menu:set_question(1)
  end
end


function menu:set_question(i)
  if i > #questions then
    menu:finish()
    return
  end
  prompt_surface:set_text_key(questions[i].prompt_key)
  options_surfaces = {}
  cursor_index = 1
  for j, opt in ipairs(questions[i].options) do
    options_surfaces[j] = sol.text_surface.create{
      font=font, font_size=font_size,
      horizontal_alignment = "center",
      text_key = opt.key,
    }
  end
  menu:update_selection()
end


function menu:update_selection()
  for i, opt in ipairs(options_surfaces) do
    if i == cursor_index then
      opt:set_color_modulation({255,255,255})
    else
      opt:set_color_modulation({100,100,100})
    end
  end
end


function menu:finish()
  local new_menu = require("scripts/menus/title_screen/main_menu")
  local top_menu = menu.top_menu
  sol.menu.start(top_menu, new_menu)
  top_menu:set_current_submenu(new_menu)
  sol.menu.stop(menu)
  settings.set_value("initial_setup_questions_asked", true)
end


function menu:move_cursor(dir)
  sol.sound.create("cursor"):play()
  cursor_index = cursor_index + dir
  if cursor_index > #options_surfaces then cursor_index = 1 end
  if cursor_index < 1 then cursor_index = #options_surfaces end
  menu:update_selection()
end



function menu:on_draw(dst)
  prompt_surface:draw(dst, ox, oy)
  for i, opt in ipairs(options_surfaces) do
    opt:draw(dst, ox, oy + i * 16 + 12)
  end
end


function menu:process_input(cmd)
  if cmd == "down" then
    menu:move_cursor(1)
  elseif cmd == "up" then
    menu:move_cursor(-1)
  elseif cmd == "confirm" then
    menu:process_selection()
  end
end


function menu:process_selection()
  if current_question == 1 then
    --Keyboard style:
    local choices = {"kbm", "keyboard"}
    settings.set_value("keyboard_controls_style", choices[cursor_index])
    settings.save()
    controls_manager.load_keyboard_mapping_set(choices[cursor_index])
  end

  menu:set_question(current_question + 1)
end



return menu
