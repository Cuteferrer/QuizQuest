--[[
By Max Mraz, licensed MIT

Created a vignette effect around the edges of the screen
--]]

local menu = {}

local game_meta = sol.main.get_metatable"game"
local vignette = sol.surface.create"effects/vignette.png"
local default_opacity = 60
local opacity = default_opacity
vignette:set_opacity(opacity)


game_meta:register_event("on_started", function(game)
  if not sol.menu.is_started(menu) then
    sol.menu.start(game, menu)
  end
end)

function game_meta:get_vignette()
  return menu
end


function menu:on_draw(dst)
  vignette:draw(dst)
end


function menu:set_opacity(new_opacity)
  opacity = new_opacity
  vignette:set_opacity(opacity)
end


function menu:set_source(new_png)
  vignette = sol.surface.create(new_png)
  vignette:set_opacity(opacity)
end


function menu:set_size(new_size)
  local new_png
  if new_size == "normal" then
    new_png = "effects/vignette.png"
  elseif new_size == "small" then
    new_png = "effects/vignette_small.png"
  elseif new_size == "very_small" then
    new_png = "effects/vignette_very_small.png"
  end
  menu:set_source(new_png)
end


function menu:set_preset(preset)
  if preset == "normal" or preset == nil then
    menu:set_size("normal")
    vignette:set_opacity(default_opacity)
  elseif preset == "dark" then
    menu:set_size("very_small")
    vignette:set_opacity(250)
  end
end


return menu