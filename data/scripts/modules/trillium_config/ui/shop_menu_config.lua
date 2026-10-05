return {
  show_price_on_icon = false, --Determines whether to put the price on the item icon. If not, be sure to display it in the description aux menu.
  currency_symbol_position = "after", --Can be "before" or "after"
  currency_symbol = "menu.shop.currency_symbol",
  menu_decoration_png = "sprites/menus/decoration/filigree_shop.png", --some PNG to be drawn above the menu as decoration
  purchase_confirmation_dialog = "menus.shop.purchase_confirm",
  sell_confirmation_dialog = "menus.shop.sell_confirm",

  --Main Grid
  base_grid_config = {
    origin = {x = 16, y = 38},
    grid_size = {columns=4, rows=4},
    cell_size = {width=32, height=32},
    cell_spacing = 4,
    edge_spacing = 4,
    background_png = nil,
    background_9slice_config = {
      width = 160, height = 160
    },
    cell_png = "menus/inventory/circle_cell.png",
    cursor_sound = "cursor",
  },
  --Name box:
  name_box_x = 104,
  name_box_y = 205,
  --Description box:
  description_box_x = 180,
  description_box_y = 38,
  --Command Legend:
  command_legend_x = 16,
  command_legend_y = 220,
  --Money HUD
  money_hud_x = 16,
  money_hud_y = 202,
  --Decoration
  decoration_x = 0,
  decoration_y = -24,
}
