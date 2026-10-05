local builder = {}
local panel_factory = require("scripts/modules/trillium/ui/hud/item_panel_factory")

local panel_spacing = 40
local DEFAULT_DURATION = 2500

function builder:new(game, config)
  local queue = {
    dst_x = config.x, dst_y = config.y
  }
  local panel_duration = config.duration or DEFAULT_DURATION
  local panels = {}

  function game:show_item_hud_panel(item_id, variant)
    local panel = panel_factory.new()
    local init_index = #panels + 1
    panel:set_item(item_id, variant)
    --Position queue based on any panels above it:
    panel.x = queue.dst_x
    if #panels > 0 then
      panel.y = (panels[#panels].y + panel_spacing)
    else
      panel.y = queue.dst_y
    end
    table.insert(panels, panel)
    sol.menu.start(queue, panel)

    --Show panel for a limited time:
    sol.timer.start(game, panel_duration, function()
      --Find this panel's index:
      local panel_index
      for i, p in ipairs(panels) do
        if p == panel then
          panel_index = i
          break
        end
      end
      --If panel is already gone, we're done here
      if not panel_index then return end
      panel:fade_out(function()
        sol.menu.stop(panel)
      end)
      --Scoot panels up:
      for i = 1, #panels do
        local p = panels[i]
        local m = sol.movement.create("straight")
        m:set_angle(math.pi / 2)
        m:set_speed(90)
        m:set_max_distance(panel_spacing)
        m:start(p)
      end
      --Remove from panels array:
      table.remove(panels, panel_index)
    end)
  end


  return queue
end


return builder
