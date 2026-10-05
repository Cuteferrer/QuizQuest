local factory = {}


function factory.new(config)
  local max_amount_function = config.max_amount_function
  local current_amount_function = config.current_amount_function
  local DRAW_RATIO = config.draw_ratio or 4
  local color = config.color or "red"
  local background_sprite = config.background_sprite or "hud/stat_bars/background"
  local background_opacity = config.background_opacity or 255
  local endcap_sprite = config.endcap_sprite or "hud/stat_bars/endcap"
  local CHECK_FREQUENCY = config.check_frequency or 30
  local time_before_fade = config.time_before_fade
  local amount_changed_callback = config.amount_changed_callback

  local bar = {}
  bar.dst_x, bar.dst_y = config.x, config.y
  bar.color = color
  local fade_on_suspend = config.fade_on_suspend

  local quest_width, quest_height = sol.video.get_quest_size()
  bar.surface = sol.surface.create(400, 8)
  bar.background = sol.sprite.create(background_sprite)
  bar.background:set_opacity(background_opacity)
  bar.foreground = sol.sprite.create("hud/stat_bars/" .. bar.color)
  bar.endcap = sol.sprite.create(endcap_sprite)
  bar.endcap:set_opacity(background_opacity)
  bar.amount_displayed = 0
  bar.width, bar.height = bar.background:get_size()


  function bar:on_started()
    local check_timer = sol.timer.start(bar, 0, function()
      bar:check()
      return CHECK_FREQUENCY
    end)
    if time_before_fade then bar.surface:set_opacity(0) end
  end


  function bar:check()
    local current_amount = current_amount_function()
    bar.current_amount = current_amount
    local need_rebuild = false

    if current_amount ~= bar.amount_displayed then
      need_rebuild = true
      local increment = 1
      local difference = current_amount - bar.amount_displayed
      if difference % 10000 == 0 then
        increment = 10000
      elseif difference % 1000 == 0 then
        increment = 1000
      elseif difference % 100 == 0 then
        increment = 100
      elseif difference % 10 == 0 then
        increment = 10
      else
        increment = 1
      end
      if current_amount < bar.amount_displayed then
        increment = increment * -1
      end
      bar.amount_displayed = bar.amount_displayed + increment
    end
    -- Redraw the surface only if something has changed.
    if need_rebuild then
      bar:rebuild_surface()
    end

  end


  function bar:rebuild_surface()
    local max_amount = max_amount_function()
    bar.surface:clear()
    bar.surface:set_opacity(255)
    bar.background:draw_region(0, 0, max_amount / DRAW_RATIO, 8, bar.surface, 0, 0)
    bar.foreground:draw_region(0, 0, bar.amount_displayed / DRAW_RATIO, 8, bar.surface, 0, 0)
    bar.endcap:draw(bar.surface, (max_amount / DRAW_RATIO - 8), 0)

    if time_before_fade then
      if bar.fade_timer then bar.fade_timer:stop() end
      bar.fade_timer = sol.timer.start(time_before_fade, function()
        bar.surface:fade_out()
      end)
    end

    if amount_changed_callback then amount_changed_callback(bar) end
  end


  function bar:on_draw(dst_surface)
    local x, y = bar.dst_x, bar.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end
    bar.surface:draw(dst_surface, x, y)
  end


  function bar:set_color(new_color)
    bar.color = new_color
    bar.foreground = sol.sprite.create("hud/stat_bars/" .. new_color)
    bar:rebuild_surface()
  end

  if fade_on_suspend then
    function bar:on_paused()
      bar.surface:fade_out()
    end
    function bar:on_unpaused()
      bar.surface:fade_in()
    end
  end

  return bar
end

return factory

