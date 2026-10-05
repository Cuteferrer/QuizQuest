--[[
Foot for the pause menu - just a dark background, but command legends should be positioned over this as aux menus
--]]

local footer_height = 24

local menu = {}
local screen_w, screen_h = sol.video.get_quest_size()

local bg = sol.surface.create(screen_w, footer_height)
bg:fill_color({0,0,0, 80})

function menu:on_draw(dst)
  bg:draw(dst, 0, screen_h - footer_height)
end

return menu

