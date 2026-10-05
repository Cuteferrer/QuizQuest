--[[
Created by Max Mraz, licensed MIT
--]]

local game_meta = sol.main.get_metatable"game"
local menu = {}


local icon_duration = 2000

local icon = sol.surface.load("sprites/hud/quest_log_icon.png")


function menu:on_draw(dst)
  icon:draw(dst, 368, 200)
  --icon:draw(dst, 100, 100)
end


function menu:start_self(game)
  if menu.show_timer and sol.menu.is_started(menu) then
    menu.show_timer:set_remaining_time(icon_duration)
  elseif sol.menu.is_started(menu) then
    sol.menu.stop(menu)
    sol.menu.start(game, menu)
  else
    sol.menu.start(game, menu)
  end
end


function menu:on_started()
  local game = sol.main.get_game()
  icon:fade_in()
  menu.show_timer = sol.timer.start(game, icon_duration, function()
    menu.show_timer = nil
    sol.menu.stop(menu)
  end)
end




function game_meta:show_quest_log_icon()
  menu:start_self(self)
end



return menu

