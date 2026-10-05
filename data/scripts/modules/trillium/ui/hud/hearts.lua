--[[
Hearts HUD.
--]]

local builder = {}
local heart_sprite = sol.sprite.create("hud/heart")
local heart_w, heart_h = heart_sprite:get_size() --expected to be 8, 8
local heart_change_frequency = 20 --how quickly the hearts empty / refill (it doesn't happen all at once)
local check_freq = 500

function builder:new(game, config)
  local menu = {}
  local hearts_per_line = config.hearts_per_line or 8
  local num_rows = config.num_rows or 3
  local heart_spacing = config.heart_spacing or 0
  menu.dst_x = config.x
  menu.dst_y = config.y
  local hearts_surface = sol.surface.create(
    hearts_per_line * (heart_w + heart_spacing),
    (heart_h + heart_spacing) * num_rows
  )

  game.event_manager:subscribe("on_healed", function()
    menu:check()
  end)

  game.event_manager:subscribe("on_hurt", function()
    menu:check()
  end)

  function menu:on_started()
    --Initialize health values:
    menu.max_health = game:get_max_life()
    menu.current_health = game:get_life()
    menu.displayed_health = menu.current_health
    --Initial build
    menu:rebuild_surface()
    --Start checking for changes
    sol.timer.start(game, check_freq, function()
      menu:check()
      return true
    end)
  end

  function menu:check()
    local needs_rebuild = false
    if menu.current_health ~= game:get_life() or menu.max_health ~= game:get_max_life() then
      needs_rebuild = true
    end
    if needs_rebuild then
      menu:rebuild_surface()
    end
  end

  function menu:rebuild_surface()
    menu.current_health = game:get_life()
    menu.max_health = game:get_max_life()
    if menu.increment_timer_started then
      return --we're already updating
    end
    menu.increment_timer_started = true
    menu.increment_timer = sol.timer.start(game, 0, function()
      menu:step_displayed_health()
      menu:update_surface()
      if menu.displayed_health == menu.current_health then
        menu.increment_timer_started = false --done updating
      else
        return heart_change_frequency
      end
    end)
  end

  function menu:step_displayed_health()
    if menu.displayed_health == menu.current_health then return end
    local step = (menu.displayed_health < menu.current_health) and 1 or -1
    menu.displayed_health = menu.displayed_health + step
  end

  function menu:update_surface()
    hearts_surface:clear()
    local total_hearts = menu.max_health / 2
    local full_hearts = math.floor(menu.displayed_health / 2)
    local half_hearts = math.floor(menu.displayed_health % 2)
    local empty_hearts = (menu.max_health / 2) - full_hearts - half_hearts

    local function which_anim(i)
      if i <= full_hearts then
        return "full"
      elseif i <= full_hearts + half_hearts then
        return "half"
      elseif i <= total_hearts then
        return "empty"
      end
    end

    for i = 1, total_hearts do
      local col = (i - 1) % hearts_per_line
      local row = math.floor((i - 1) / hearts_per_line)
      local x = col * (heart_w + heart_spacing)
      local y = row * (heart_h + heart_spacing)
      heart_sprite:set_animation(which_anim(i))
      heart_sprite:draw(hearts_surface, x + heart_w / 2, y + heart_h - 3)
    end
  end

  function menu:on_draw(dst)
    hearts_surface:draw(dst, menu.dst_x, menu.dst_y)
  end

  return menu
end


return builder

