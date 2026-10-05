local status_bar_factory = require"scripts/modules/trillium/ui/hud/bar_factory"
local hero_meta = sol.main.get_metatable"hero"

local builder = {}


local BAR_COLORS = {
  burn = "burn",
  poison = "poison",
  acid = "green",
  cold = "cold",
  bleed = "bleed",
}


function builder:new(game, config)
  --this menu will display any active status bars
  local menu = {}
  menu.bars = {}
  menu.active_statuses = {}

  menu.x, menu.y = config.x or 32, config.y or 48
  local hero = game:get_hero()


  function menu:on_started()
    menu.bars = {}
    menu.active_statuses = {}
    --Set current status levels:
    for status, _ in pairs(BAR_COLORS) do
      local amount = hero:get_status_effect_buildup(status)
      if amount > 0 then
        menu:add_status_bar(status)
      end
    end
  end


  function menu:on_finished()
    for _, bar in pairs(menu.bars) do
      menu:remove_bar(bar)
    end
  end


  --Add New Status Bar
  function menu:add_status_bar(status)
    if not BAR_COLORS[status] then return end --don't show a status bar if we didn't set up a color for it
    menu.active_statuses[status] = true

    local function max_amount_function() return game:get_value("status_resistance_" .. status) or 100 end
    local function current_amount_function()
      return hero:get_status_effect_buildup(status)
    end
    local function amount_changed_callback(bar)
      local amount = bar.current_amount
      --Remove from queue if status is at 0
      if amount <= 0 and not bar.removing then
        bar.removing = true
        menu:remove_bar(bar)
      end
    end
    local bar_config = {
      draw_ratio = 2,
      color = BAR_COLORS[status],
      max_amount_function = max_amount_function,
      current_amount_function = current_amount_function,
      amount_changed_callback = amount_changed_callback,
      x = 180, y = 120,
    }
    local bar = status_bar_factory.new(bar_config)
    bar.status = status
    bar.on_draw = nil

    menu.bars[#menu.bars + 1] = bar
    sol.menu.start(menu, bar)
  end


  --Remove status bar
  function menu:remove_bar(bar)
    menu.active_statuses[bar.status] = nil
    for i, v in ipairs(menu.bars) do
      if v == bar then table.remove(menu.bars, i) end
    end
    sol.menu.stop(bar)
  end


  --Draw all status bars
  function menu:on_draw(dst)
    for i, bar in ipairs(menu.bars) do
      bar.surface:draw(dst, 0 + menu.x, (i - 1) * 8 + menu.y)
    end
  end


  --Create status bars when a not-already-shown status is built up
  hero_meta:register_event("on_status_build_up", function(hero, status)
    if not menu.active_statuses[status] then
      menu:add_status_bar(status)
    end
  end)

  return menu
end

return builder

