--cell width is width * columns + cell_spacing * (columns - 1) + edge spacing + 2
--WIDTH (32x32 cells, 4 spacing, 4 edge)(5 cells wide): 

local manager = {}

local default_conf = {
  origin = {x = 8, y = 74},
  grid_size = {columns=5, rows=3},
  cell_size = {width=32, height=32},
  cell_spacing = 4,
  edge_spacing = 4,
  background_png = "menus/inventory/grid_background.png",
  background_offset = {x = 0, y = -6},
  cell_png = "menus/inventory/circle_cell.png",
  cursor_sound = "cursor",
  --category_scroll_lock = true,
  --cursor_edge_behavior = "increment",
  --cell_color = {40,40,30}
}

function manager.get_config(overrides)
  local config = {}
  for k, v in pairs(default_conf) do
    config[k] = v
  end
  for k, v in pairs(overrides or {}) do
    config[k] = v
  end
  return config
end

return manager
