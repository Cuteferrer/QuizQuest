--[[
Header for the pause menu that shows current submenu and menu swapping buttons
--]]

local header_height = 32
local title_width = 128 --how far apart the centers of the Submenu Left and Right icons are

local menu = {}
local controls_manager = sol.controls.get_controls_manager()
local font, font_size = sol.modules.get_object("language_manager").get_menu_font()
local screen_w, screen_h = sol.video.get_quest_size()
local hearts_factory = require("scripts/modules/trillium/ui/hud/hearts")


local bg = sol.surface.create(screen_w, header_height)
bg:fill_color({0,0,0, 80})
local draw_surface = sol.surface.create(screen_w, header_height)

local title_surface = sol.text_surface.create{
  font = font, font_size = font_size,
  horizontal_alignment = "center",
  vertical_alignment = "middle",
}


function menu:set_menu_title(title_name)
  local string_id = "menu.pause." .. title_name
  title_surface:set_text_key(string_id)
  menu:update()
end

function menu:update()
  local l_id, l_anim = controls_manager:get_command_sprite_id("submenu_left")
  local r_id, r_anim = controls_manager:get_command_sprite_id("submenu_right")
  local l_sprite = sol.sprite.create(l_id)
  l_sprite:set_animation(l_anim)
  local r_sprite = sol.sprite.create(r_id)
  r_sprite:set_animation(r_anim)
  local center_x = screen_w / 2
  local center_y = header_height / 2
  --Clear draw surface:
  draw_surface:clear()
  --Draw bg:
  bg:draw(draw_surface, 0, 0)
  --Set/Draw title text:
  title_surface:draw(draw_surface, center_x, center_y)
  --Draw Submenu Swap Icons:
  l_sprite:draw(draw_surface, center_x - title_width / 2, center_y + 5)
  r_sprite:draw(draw_surface, center_x + title_width / 2, center_y + 5)
end


function menu:on_started()
  menu:update()
  local tlx, tly = 8, 0
  local hearts_hud = require("scripts/modules/trillium/ui/hud/hearts"):new(
    sol.main.get_game(),
    {
      x = tlx,
      y = tly + 12,
    }
  )
  sol.menu.start(menu, hearts_hud)
end

function menu:on_draw(dst)
  draw_surface:draw(dst, 0, 0)
end

return menu

