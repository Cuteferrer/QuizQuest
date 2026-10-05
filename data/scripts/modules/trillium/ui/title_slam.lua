--[[
Created by Max Mraz, licensed MIT
A script to do a title slam. Must be required (probably in features.lua)
This is strictly a worse version of location_titles.lua
--]]

local menu = {}

local slam_duration = 2500

local screen_width, screen_height = sol.video.get_quest_size()

local txt_surface = sol.text_surface.create{
  font = "EgyptienneLarge",
  font_size = 64,
  vertical_alignment = "middle",
  horizontal_alignment = "center",
}

function menu:on_started()
  sol.audio.play_sound"drum_low"
  txt_surface:set_text(menu.title_text)
  if menu.display_timer then menu.display_timer:stop() end
  menu.display_timer = sol.timer.start(menu, slam_duration, function()
    sol.menu.stop(menu)
  end)
end


function menu:on_draw(dst)
  txt_surface:draw(dst, screen_width / 2, screen_height / 2 )
end


local map_meta = sol.main.get_metatable"map"

function map_meta:title_slam(text, duration)
  menu.title_text = text
  slam_duration = duration or 2500
  sol.menu.start(self, menu)
end

return menu
