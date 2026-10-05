local builder = {}

local menu_width = 96
local pre_update_delay = 400
local bar_update_freq = 20
local bar_update_step = 2
local show_duration = 2000
local fade_out_duration = 1000


function builder:new(game, config)
  local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()
  local menu = { x = config.x or 0, y = config.y or 0 }
  local bar_width = config.bar_width or 48
  local bar_height = config.bar_height or 4

  local exp_surface = sol.surface.create(bar_width, 48)
  local exp_bar_outline = sol.surface.create(bar_width, bar_height)
  exp_bar_outline:fill_color(sol.colors.ui_off_white)
  local exp_bar_bg = sol.surface.create(bar_width - 2, bar_height - 2)
  exp_bar_bg:fill_color(sol.colors.ui_grey_dark)
  local exp_bar_fill = sol.surface.create(bar_width - 2, bar_height - 2)
  exp_bar_fill:fill_color{0,160,160}
  local exp_text = sol.text_surface.create{
    font = font, font_size = font_size,
    horizontal_alignment = "left",
    vertical_alignment = "top",
  }


  function game:update_exp_hud(amount)
    --tightly couples this component to the EXP management code, but prevents need for a timer to check if there's a mismatch all the time
    menu:add_exp(amount)
  end


  function menu:on_started()
    menu.actual_exp = game:get_exp()
    menu.displayed_exp = game:get_exp()
    menu.displayed_number = 0
    exp_surface:set_opacity(0)

    --[[check:
    sol.timer.start(menu, 100, function()
      local exp = game:get_exp()
      if menu.actual_exp ~= exp then
        menu:add_exp(exp - menu.actual_exp)
      end
      return true
    end)
    --]]
  end


  function menu:update()
    exp_surface:clear()
    local bar_length = menu.displayed_exp / menu.required_exp * bar_width
    exp_bar_outline:draw(exp_surface, 0, 0)
    exp_bar_bg:draw(exp_surface, 1, 1)
    exp_bar_fill:draw_region(0, 0, bar_length, bar_height, exp_surface, 1, 1)
    if game.show_exp_numbers then
      exp_text:draw(exp_surface, 0, 2)
    end
  end


  function menu:add_exp(amount)
    local current_level = game:get_level()
    menu.required_exp = game:get_required_exp(current_level + 1)
    menu.actual_exp = game:get_exp()
    menu.displayed_number = math.floor(menu.displayed_number + amount)
    if not menu.active then
      exp_surface:fade_in(10)
      exp_text:set_text("")
      menu.active = true
    end
    if menu.update_timer then menu.update_timer:stop() end
    if menu.fade_out_timer then menu.fade_out_timer:stop() end
    if menu.preupdate_timer then menu.preupdate_timer:stop() end

    --Pause for a sec before scrolling up so you can see the jump better:
    menu.preupdate_timer = sol.timer.start(menu, pre_update_delay, function()
      menu.update_timer = sol.timer.start(menu, 0, function()
        if menu.displayed_exp < menu.actual_exp then
          local diff = menu.actual_exp - menu.displayed_exp
          local step = 1
          if diff > 10000 then step = 1000
          elseif diff > 1000 then step = 500
          elseif diff > 150 then step = 100
          elseif diff > 50 then step = 25
          elseif diff > 10 then step = 5
          else step = 1 end
          menu.displayed_exp = menu.displayed_exp + step
          exp_text:set_text(menu.displayed_number)
          menu:update()
          return bar_update_freq
        else
          menu.displayed_exp = menu.actual_exp
          menu:update()
          menu.fade_out_timer = sol.timer.start(menu, show_duration, function()
            exp_text:set_text("")
            menu.active = false
            menu.displayed_number = 0
            exp_surface:fade_out(20)
          end)
        end

      end)
    end)
  end


  function menu:on_draw(dst)
    exp_surface:draw(dst, menu.x, menu.y)
  end

  return menu

end


return builder
