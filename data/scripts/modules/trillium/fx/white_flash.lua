--[[
Created by Max Mraz, licensed MIT
Creates a flash of solid color that obscures the screen

Useage:
game:start_flash(color, fade_in_time)
Then you must explicitly stop it:
game:stop_slash(fade_out_time)

Defaults as a white flash that fades in and out VERY quickly
--]]

local menu = {}

local white_surface = sol.surface.create()
white_surface:fill_color{255,255,255}

local fade_time = 2

function menu:on_started()
  white_surface:set_opacity(0)
  white_surface:fade_in(fade_time)
end

function menu:fade_out(delay, callback)
  if type(delay) == "function" then
    callback = delay
    delay = 20
  end
  if not callback then
    callback = function() print"CALLING BACK" sol.menu.stop(menu) end
  end
  white_surface:fade_out(delay, callback)
end

function menu:on_draw(dst)
  white_surface:draw(dst)
end

function menu:set_color(color)
  white_surface:fill_color(color)
end


--Add functions to the game metatable
local game_meta = sol.main.get_metatable"game"

function game_meta:start_flash(color, time)
  fade_time = time or 2
  if color then menu:set_color(color)
  else menu:set_color{255, 255, 255} end
  if sol.menu.is_started(menu) then
    sol.menu.stop(menu)
  end
  sol.menu.start(self, menu)
end

function game_meta:stop_flash(time)
  menu:fade_out(time or 20, function() sol.menu.stop(menu) end)
end

function game_meta:start_main_flash(color)
  if color then menu:set_color(color)
  else menu:set_color{255, 255, 255} end
  if sol.menu.is_started(menu) then
    sol.menu.stop(menu)
  end
  sol.menu.start(sol.main, menu)
end

return menu