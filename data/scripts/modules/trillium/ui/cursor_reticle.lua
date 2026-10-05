--[[
Created by Max Mraz, licensed MIT
Draws a cursor reticle onto the screen while keyboard input is active
--]]

local game_meta = sol.main.get_metatable"game"

local menu = {}

local cursor_sprite = sol.sprite.create("hud/cursor_reticle")
local screen_w, screen_h = sol.video.get_quest_size()


function menu:on_started()
  menu.active = false
  sol.timer.start(menu.game, 100, function()
    local game = menu.game
    local is_game_sus = game and game:is_suspended()
    menu.active = game and (sol.controls.get_controls_manager().get_active_input_type() == "keyboard") and (not is_game_sus)
    return true
  end)
end


function menu:on_draw(dst)
  if menu.active then
    local x, y = sol.input.get_mouse_position()
    if (x > 0 and y > 0) and (x < screen_w - 1 and y < screen_h - 1) then
      cursor_sprite:draw(dst, x, y)
    end
  end
end


game_meta:register_event("on_started", function(game)
  if not sol.menu.is_started(menu) then
    menu.game = game
    sol.menu.start(game, menu)
  end
end)

return menu
