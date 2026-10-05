--[[
By Max Mraz, licensed MIT

Manages opening/closing a pause menu and its submenus
--]]
local pause_background = require("scripts/menus/pause/background")
local pause_header = require("scripts/menus/pause/header")
local pause_footer = require("scripts/menus/pause/footer")
local config = require("scripts/menus/pause/pause_config")

local menu = {}
local game_meta = sol.main.get_metatable"game" --remember to require from features.lua

menu.current_submenu_index = 1
local bg_menus = { --drawn behind the main submenus, in this order:
  pause_background,
  pause_header,
  pause_footer,
}

--Start / Stop Pause Manager when game is paused:
function game_meta:on_paused()
  sol.menu.start(self, menu)
end

function game_meta:on_unpaused()
  sol.menu.stop(menu)
end


function menu:on_started()
  pause_header:set_menu_title(config.submenus[menu.current_submenu_index].name)
  --Start BG menus:
  for i, m in ipairs(bg_menus) do
    sol.menu.start(self, m)
  end
  --Start current submenu:
  menu:set_active_submenu(menu.current_submenu_index)
end

function menu:on_finished()
  --Stop BG menus (I think this is redundant, they should be in the menu manager context and therefore stop themselves when it does):
  for i, m in ipairs(bg_menus) do
    sol.menu.stop(m)
  end
end


function menu:set_active_submenu(submenu_no)
  local new_submenu = config.submenus[submenu_no].menu
  local new_title = config.submenus[submenu_no].name
  if menu.active_submenu then
    sol.menu.stop(menu.active_submenu)
  end
  menu.active_submenu = new_submenu
  pause_header:set_menu_title(new_title)
  menu.current_submenu_index = submenu_no
  sol.menu.start(menu, new_submenu)
end


function menu:next_submenu(dir)
  dir = dir or 1
  local next_index = menu.current_submenu_index + dir
  if next_index > #config.submenus then
    next_index = 1
  elseif next_index < 1 then
    next_index = #config.submenus
  end
  menu:set_active_submenu(next_index)
end


function menu:on_command_pressed(cmd)
  local handled = false
  if cmd == "submenu_left" then
    menu:next_submenu(-1)
    handled = true
  elseif cmd == "submenu_right" then
    menu:next_submenu(1)
    handled = true
  elseif cmd == "cancel" then
    sol.main.get_game():set_paused(false)
  end
  return handled
end


return menu
