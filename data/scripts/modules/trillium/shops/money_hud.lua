local bg_surface = sol.surface.load("sprites/hud/money_icon.png")
local menu = {
	x = 10, y = 202
}
menu.money_displayed = 0
local digit_offset = 12 --how far X to offset money text

local digit_text = sol.text_surface.create {
	font = "enter_command",
	font_size = 16,
	horizontal_alignment = "left",
	vertical_alignment = "top",
	text = menu.money_displayed,
}

function menu:update()
	digit_text:set_text(string.format("%03d", menu.money_displayed))
end

function menu:on_draw(dst)
	bg_surface:draw(dst, menu.x, menu.y)
	digit_text:draw(dst, menu.x + digit_offset, menu.y)
end


local function check(game)
	local should_rebuild = false
	local game = sol.main.get_game()
	local money = game:get_money()

	--Increment if needed:
	if money ~= menu.money_displayed then
		--Show more or less money:
		should_rebuild = true
		local diff = math.abs(money - menu.money_displayed)
		local step_amount = math.max(math.floor(diff / 10), 1)
		local step_direction = menu.money_displayed < money and 1 or -1
		menu.money_displayed = menu.money_displayed + step_amount * step_direction
	end

	-- Update the text if something has changed, then check again.
	if should_rebuild then
		menu:update()
		sol.timer.start(menu, 32, function()
			check(game)
		end)
	end
end


function menu:notify()
	check()
end


function menu:on_started()
	menu.money_displayed = sol.main.get_game():get_money()
	menu:update()
	check()
end

return menu
