--[[
Show the reload bar by calling:
game.reload_hud_bar:reload(1000) --where 1000 is the duration of the reload
--]]

local builder = {}

function builder:new(game, config)
  local menu = {
    x = config.x or 10,
    y = config.y or 22,
  }
  menu.elapsed_time = 0
  menu.duration = 1000

  local width = 36
  local height = 1

  local bar_bg = sol.surface.create(width + 2, height + 2)
  bar_bg:fill_color(sol.colors.ui_black)
  local bar_fg = sol.surface.create(width, height)
  bar_fg:fill_color(sol.colors.gunmetal)

  function menu:reload(duration)
    menu.visible = true
    menu.elapsed_time = 0
    menu.duration = duration
    local step = 10
    menu.elapsed_time = 0
    sol.timer.start(game, step, function()
      menu.elapsed_time = menu.elapsed_time + step
      if menu.elapsed_time < menu.duration then
        return step
      else
        sol.audio.play_sound"gun_revolver_hammer_cock"
        menu:flash()
      end
    end):set_suspended_with_map(true)
  end


  function menu:flash()
    bar_bg:fill_color(sol.colors.ui_off_white)
    sol.timer.start(game, 100, function()
      bar_bg:fill_color(sol.colors.ui_black)
      menu.visible = false
    end)
  end


  function menu:on_draw(dst)
    if menu.visible then
      bar_bg:draw(dst, menu.x, menu.y)
      bar_fg:draw_region(0, 0, (menu.elapsed_time / menu.duration) * width, height, dst, menu.x + 1, menu.y + 1)
    end
  end

  --Set on game object for access by gun manager:
  game.reload_hud_bar = menu

  return menu
end

return builder
