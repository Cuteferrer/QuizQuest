--[[
Created by Max Mraz, licensed MIT
A language selection menu
--]]

local menu = {}
local language_manager = sol.modules.get_object("language_manager")
--Config:
local vert_spacing = 24


local bg = sol.surface.create()
bg:fill_color{0,0,0}
local languages_surface = sol.surface.create()
local screen_width, screen_height = sol.video.get_quest_size()
local cursor = sol.sprite.create("menus/arrow")

function menu:init()
  local language_ids = sol.language.get_languages()
  menu.languages = {}
  menu.cursor_index = 1

  for i, id in ipairs(language_ids) do
    local lang = {}
    local font, font_size = language_manager:get_dialog_font(id)
    lang.id = id
    lang.text_surface = sol.text_surface.create{
      font = font,
      font_size = font_size,
      text = sol.language.get_language_name(id),
      --horizontal_alignment = "center"
    }
    if id == language_manager:get_default_language() then
      menu.cursor_index = i
    end
    menu.languages[i] = lang
  end

end


function menu:on_started()
  --Skip if a language is already set:
  if sol.language.get_language() ~= nil and not menu.force_choice then
    sol.menu.stop(menu)
  else
    --Generate languages table
    menu:init()
    --Draw language names:
    languages_surface:clear()
    for i, lang in ipairs(menu.languages) do
      local y = (screen_height / 2 - (#menu.languages / 2) * vert_spacing) + vert_spacing * i
      --set languages Y value so the cursor can use it:
      lang.y = y
      lang.text_surface:draw(languages_surface, 40, y)
    end

  end
end


function menu:move_cursor(dir)
  sol.audio.play_sound("cursor")
  menu.cursor_index = menu.cursor_index + dir
  if menu.cursor_index <= 0 then menu.cursor_index = #menu.languages end
  if menu.cursor_index > #menu.languages then menu.cursor_index = 1 end
end


function menu:process_selection()
  local selected_lang = menu.languages[menu.cursor_index]
  sol.language.set_language(selected_lang.id)
  menu.force_choice = nil --so you won't be forced to choose language again if you restart the program
  sol.timer.start(menu, 10, function()
    if sol.menu.is_started(menu) then sol.menu.stop(menu) end
  end)
  return true --idk will this stop the menu from looping??
end


function menu:on_draw(dst)
  bg:draw(dst)
  languages_surface:draw(dst)
  cursor:draw(dst, 24, menu.languages[menu.cursor_index].y - 4)
end


function menu:on_command_pressed(command, controls_ob)
  if command == "up" then
    menu:move_cursor(-1)
  elseif command == "down" then
    menu:move_cursor(1)
  elseif (command == "action") then
    menu:process_selection()
  elseif command == "cancel" then
    if sol.menu.is_started(menu) then sol.menu.stop(menu) end
  end

  return true --block any propagation
end


return menu
