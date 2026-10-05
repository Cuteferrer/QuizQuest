--[[
Created by Max Mraz, licensed MIT (although like, it's a config file. You can't copyright that.)

Returns standard configs for use with the Trillium Grid Menus

Usage:
local overrides = {  some_override_values }
local config = require("scripts/menus/configs/grid_config_manager").get_standard_config(overrides)
local menu = sol.modules.get_object("trilmenu_grid").create(config)

--]]
--cell width is width * columns + cell_spacing * (columns - 1) + edge spacing + 2
--WIDTH (32x32 cells, 4 spacing, 4 edge)(5 cells wide): 

local manager = {}

local configs = {
  standard = {
    origin = {x = 12, y = 44},
    grid_size = {columns=5, rows=4},
    cell_size = {width=32, height=32},
    cell_spacing = 4,
    edge_spacing = 4,
    background_9slice_config = {
      calc_from_grid = true,
    },
    background_offset = { x = -4, y = -4},
    cell_png = "menus/inventory/circle_cell.png",
    cursor_sound = "cursor",
    --category_scroll_lock = true,
    --cursor_edge_behavior = "increment",
    --cell_color = {40,40,30}
  },
}



function manager.get_config(conf_type, overrides)
  local config = {}
  local init_values = configs[conf_type]
  for k, v in pairs(init_values) do
    config[k] = v
  end
  for k, v in pairs(overrides or {}) do
    config[k] = v
  end
  return config
end

--Returns the standard grid config
--Pass a table of grid config values to override any values
function manager.get_standard_config(overrides)
  return manager.get_config("standard", overrides
)
end

return manager
