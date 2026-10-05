--[[
Created by Max Mraz, licensed MIT
Small menu that shows a controller disconnect message and suspends the game
--]]

local menu = {}

local font, font_size = sol.modules.get_object("language_manager"):get_dialog_font()
-- local bg = sol.surface.load("sprites/hud/dialog_box_background.png")
-- local bg = sol.surface.load("sprites/menus/dialog_choice_cell.png")
local bg = sol.surface.create(240, 32)
bg:fill_color({0,0,0,200})
local screen_w, screen_h = sol.video.get_quest_size()
local bgw, bgh = bg:get_size()
local txt = sol.text_surface.create({
  font = font, font_size = font_size,
  horizontal_alignment = "center",
  vertical_alignment = "middle",
  text_key = "game.hud_messages.controller_disconnected",
})

function menu:on_draw(dst)
  bg:draw(dst, screen_w / 2 - bgw / 2, screen_h / 2 - bgh / 2)
  txt:draw(dst, screen_w / 2, screen_h / 2)
end


function menu:on_command_pressed(cmd)
  local handled = false
  if cmd == "confirm" or cmd == "cancel" then
    sol.menu.stop(menu)
    handled = true
  end
  return handled
end

return menu
