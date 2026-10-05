local map_meta = sol.main.get_metatable"map"
local tone_presets = require("scripts/modules/trillium/fx/lighting/tone_presets")


--Create "tone_menu", which has a surface that can change colors, and will be overlaid onto the map to create a "color correction" effect
local menu = {}
local screen_width, screen_height = sol.video.get_quest_size()
local bleed = 16
local width, height = screen_width + bleed * 2, screen_height + bleed * 2
local default_color = {255,255,255}
menu.surface = sol.surface.create(width, height)
menu.surface:set_blend_mode"multiply"
menu.current_color = default_color
menu.target_color = default_color

function menu:on_draw(dst)
  menu.surface:draw(dst, bleed * -1, bleed * -1)
end


--Color compare function:
local function do_colors_match(a, b)
  local match = false
  if a[1] == b[1] and a[2] == b[2] and a[3] == b[3] then match = true end
  return match
end

--skew one number toward another:
local function move_number_toward(a, b, amount)
  amount = amount or 1
  local dir = a > b and -1 or 1
  if a == b then dir = 0 end
  a = a + amount * dir
  return a
end


--set new color on menu surface:
function menu:set_new_color(color, fade_delay)
  fade_delay = fade_delay or 10
  menu.target_color = color
  if menu.tone_fade_timer then menu.tone_fade_timer:stop() end --stop timer if already started

  menu.tone_fade_timer = sol.timer.start(sol.main, 0, function()
    if not do_colors_match(menu.current_color, menu.target_color) then
      for i = 1, 3 do
        menu.current_color[i] = move_number_toward(menu.current_color[i], menu.target_color[i])
      end
      menu.surface:clear()
      menu.surface:fill_color(menu.current_color)
      --print("Filling with color:", menu.current_color[1], menu.current_color[2], menu.current_color[3])
      return fade_delay
    end
  end)
end


--set a new color without any fading:
function menu:set_new_color_immediately(color)
  --print("Filling color", color[1], color[2],color[3])
  menu.target_color = color
  menu.current_color = color
  menu.surface:clear()
  menu.surface:fill_color(color)
end


--Set map color tone:
function map_meta:set_tone(tone, fade_delay)
  --print("SETTING TONE:", tone)
  local map = self
  --Start menu if not already started:
  if sol.menu.is_started(menu) then
    sol.menu.stop(menu)
  end
  sol.menu.start(map, menu)
  --Update tone:
  local color = tone_presets.get_tone_from_preset(tone)
  if fade_delay then
    menu:set_new_color(color, fade_delay)
  else
    menu:set_new_color_immediately(color)
  end
end


