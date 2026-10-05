--[[
Created by Max Mraz, licensed MIT
A menu to allow interaction with several save slots

Usage - load a file:
file_select_menu:set_mode("load")
sol.menu.start(sol.main, file_select_menu())

Usage - overwrite an existing save slot with a new game:
file_select_menu:set_mode("new_game")
sol.menu.start(sol.main, file_select_menu())
--]]

local nineslice = sol.modules.get_object("trilmenu_nineslice")
local load_game = require("scripts/menus/title_screen/load_game")
local confirmation_factory = sol.modules.get_object("trilmenu_component_confirmation")
local font, font_size = sol.modules.get_object("language_manager").get_menu_font()

local menu = {x = 0, y = 4}

local num_save_slots = 4
local savename_prefix = "save"
local panel_width, panel_height = 400, 56
local menu_width, menu_height = 416, panel_height * num_save_slots + 16
local panel_spacing = 8

local cursor_index = 1

function menu:on_started()
  menu.draw_surface = sol.surface.create(panel_width, panel_height * num_save_slots)
  menu.cursor = sol.sprite.create("menus/arrow")
  menu.bg_surface = nineslice.get_surface{
    width = menu_width, height = menu_height - panel_spacing,
    source_png = "menus/panel_blocks/small.png",
    tile_width = 8, tile_height = 8,
  }

  for i = 1, num_save_slots do
    local slot_surface = nineslice.get_surface{
      width = panel_width, height = panel_height - panel_spacing,
      source_png = "menus/panel_blocks/subdivider.png",
      tile_width = 8, tile_height = 8,
    }

    local slot_name_surface = sol.text_surface.create{
      font = font, font_size = font_size,
      text = sol.language.get_string("menu.title_screen.file_select.slot") .. ": " .. i,
    }

    local slot_details_surface = sol.text_surface.create{
      font = font, font_size = font_size,
    }
    local playtime_surface = sol.text_surface.create{
      font = font, font_size = font_size, horizontal_alignment = "right",
    }
    local location_surface = sol.text_surface.create{
      font = font, font_size = font_size, horizontal_alignment = "right",
    }
    if menu:does_save_exist(i) then
      --Set player info:
      local file_info = menu:read_save_details(i)
      local player_name = file_info.player_name or ""
      local total_playtime = file_info.total_playtime or ""
      local last_location = file_info.last_location or ""
      slot_details_surface:set_text(player_name)
      --Set playtime info:
      local hrs, mins, secs = math.floor(total_playtime / 3600), math.floor(total_playtime % 3600 / 60), total_playtime % 60
      playtime_surface:set_text(string.format("%d:%02d:%02d", hrs, mins, secs))
      --Last location:
      if last_location then location_surface:set_text(sol.language.get_string("locations." .. last_location)) end
    else
      slot_details_surface:set_text_key("menu.title_screen.file_select.new_game")
    end
    slot_name_surface:draw(slot_surface, 16, 16)
    slot_details_surface:draw(slot_surface, 16, 32)
    playtime_surface:draw(slot_surface, panel_width - 8, 16)
    location_surface:draw(slot_surface, panel_width - 8, 32)
    slot_surface:draw(menu.bg_surface, 8, (panel_height) * (i - 1) + 8)
  end
end


function menu:move_cursor(dir)
  cursor_index = cursor_index + dir
  if cursor_index > num_save_slots then
    cursor_index = 1
  elseif cursor_index <= 0 then
    cursor_index = num_save_slots
  end
  sol.audio.play_sound"cursor"
end


function menu:on_draw(dst)
  menu.bg_surface:draw(dst, menu.x, menu.y)
  menu.cursor:draw(dst, 8 + menu.x, cursor_index * panel_height - panel_height / 2 + menu.y )
end


function menu:on_command_pressed(cmd)
  if cmd == "up" then
    menu:move_cursor(-1)
  elseif cmd == "down" then
    menu:move_cursor(1)
  elseif cmd == "cancel" then
    sol.menu.stop(menu)
  elseif cmd == "confirm" then
    menu:process_selection(cursor_index)
  end
  return true --never let input propagate
end





function menu:set_mode(mode)
  local modes = {
    ["load"] = true,
    ["new_game"] = true,
  }
  assert(modes[mode], "Invalid mode string passed to file_select_menu:set_mode()")
  menu.mode = mode
end


function menu:process_selection(slot_no)
  if (menu.mode == "load") or (menu.mode == nil) then --Load existing file or start new game in empty file
    menu:load_slot(slot_no)
  elseif menu.mode == "new_game" then
    if not menu:does_save_exist(slot_no) then
      menu:load_slot(cursor_index)
    else
      menu:overwrite_slot(slot_no)
    end
  end
end


function menu:does_save_exist(slot_no)
  return sol.file.exists(savename_prefix .. slot_no .. ".dat")
end


function menu:do_any_saves_exist()
  local exist = false
  for i = 1, num_save_slots do
    if menu:does_save_exist(i) then
      exist = true
      break
    end
  end
  return exist
end


function menu:read_save_details(slot_no)
  local file_info = {
    hero_class = "",
    hero_level = "0",
    total_playtime = "0",
    last_location = nil,
  }
  local file = sol.file.open(savename_prefix .. slot_no .. ".dat")
  for line in file:lines() do
    for k, v in line:gmatch('(.-) = "(.-)"$') do
      if k == "hero_class" then file_info[k] = v end
      if k == "last_checkpoint_location_id" then file_info["last_location"] = v end
    end
    for k, v in line:gmatch('(.-) = (.-)$') do
      if k == "hero_level" then file_info[k] = v end
      if k == "total_playtime" then file_info[k] = v end
    end
  end
  file:close()
  return file_info
end



function menu:load_slot(slot_no)
  menu.parent_menu.load_game_freeze = true
  load_game:set_filename(savename_prefix .. slot_no .. ".dat")
  sol.menu.stop(menu)
  sol.menu.start(sol.main, load_game)
end


function menu:clear_slot(slot_no)
  local filename = savename_prefix .. slot_no .. ".dat"
  sol.game.delete(filename)
end


function menu:overwrite_slot(slot_no)
  local confirm_menu = confirmation_factory.new{
    message_key = "menu.title_screen.file_select.overwrite_confirmation",
    callback = function(choice)
      if choice == 1 then
        menu:clear_slot(slot_no)
        menu:load_slot(slot_no)
      end
    end
  }
  sol.menu.start(menu, confirm_menu)
end


return menu
