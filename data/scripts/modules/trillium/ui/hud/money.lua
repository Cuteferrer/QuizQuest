local builder = {}

local money_icon = sol.surface.create("hud/money_icon.png")
local fade_away_delay = 3000


function builder:new(game, config)
	local menu = {}
	local x, y = config.x, config.y
	local digit_x, digit_y = config.x + 12, config.y
	local money_displayed = game:get_money()
	local digit_text = sol.text_surface.create{
    font = "enter_command",
    font_size = 16,
    horizontal_alignment = "left",
    vertical_alignment = "top",
    text = money_displayed,
	}


	function menu:set_hidden(should_hide)
		menu.is_hidden = should_hide
		if should_hide then
	    local fade_speed = 40
	    money_icon:fade_out(fade_speed)
	    digit_text:fade_out(fade_speed)
	  else
	  	money_icon:fade_in()
	    digit_text:fade_in()
	  end
	end


	function menu:on_draw(dst)
		money_icon:draw(dst, x, y)
		digit_text:draw(dst, digit_x, digit_y)
	end


	local function check()
		local should_rebuild = false
		local money = game:get_money()

		--Override to force money to show (great for shops lol)
		if game.force_money_display and menu.is_hidden then
			menu:set_hidden(false)
		end

		--Increment if needed:
		if money ~= money_displayed then
			--Show timer if hidden:
			if menu.is_hidden then menu:set_hidden(false) end
			should_rebuild = true
			--Show more or less money:
      local diff = math.abs(money - money_displayed)
      local step_amount = math.max(math.floor(diff / 10), 1)
      local step_direction = money_displayed < money and 1 or -1
      money_displayed = money_displayed + step_amount * step_direction
      --Prevent hiding hud for a little bit:
      menu.recently_changed = true
      if menu.hide_timer then menu.hide_timer:stop() end
      menu.hide_timer = sol.timer.start(menu, fade_away_delay, function() menu.recently_changed = false end)
    else --don't need to increment
      if not menu.is_hidden and not menu.recently_changed and not game.force_money_display then
	      menu:set_hidden(true)
      end
		end

    -- Update the text if something has changed.
    if should_rebuild then
      digit_text:set_text(string.format("%03d", money_displayed))
    end

    return true  -- Repeat the timer.
	end

  -- Periodically check.
  sol.timer.start(game, 30, function()
    if sol.menu.is_started(menu) then check() end
    	return true
  end)

	return menu

end


return builder