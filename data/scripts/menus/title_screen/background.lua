local menu = {}

local background = sol.surface.create("menus/title_screen/test_background_2.png")
local title = sol.sprite.create("menus/title_screen/title")

local width, height = background:get_size()
local tw, th = title:get_size()
local title_x = (width / 2)
local title_y = (height / 2)
--Squash title:
title:set_scale(1, 0)


local function unsquash_title()
  --sol.audio.play_sound("spells/spell_charge")
  sol.timer.start(sol.main, 10, function()
    sol.audio.play_music("title_thoughtful_wind")
  end)
  local y_scale = 0
  sol.timer.start(menu, 20, function()
    y_scale = y_scale + .1
    title:set_scale(1, y_scale)
    if y_scale < 1 then
      return true
    else

    end
  end)
end


function menu:on_started()
  unsquash_title()
end



function menu:on_draw(dst)
  background:draw(dst)
  title:draw(dst, title_x, title_y)
end

return menu
