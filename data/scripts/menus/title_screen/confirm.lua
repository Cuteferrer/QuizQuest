local menu = require("scripts/menus/title_screen/title_menu_factory").new({
  x = 190,
  y = 150,
  cursor_offset = {x = -3, y = -3},
  options = {
      "confirm",
      "cancel",
    },
})


function menu:process_selection(option)
  if option == "confirm" then
    menu.confirmation_callback()
    menu:switch_to_menu(menu.parent_menu)
  elseif option == "cancel" then
    menu:switch_to_menu(menu.parent_menu)
  end
end

return menu
