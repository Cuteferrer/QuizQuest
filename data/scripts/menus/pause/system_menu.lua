--[[
By Max Mraz, licensed MIT

System Options, like Save, Quit, Options, etc.
--]]
local command_legend_defaults = require("scripts/menus/pause/inventory/command_legend_defaults").new({
  { command = "confirm",  action = "menu.actions.confirm"},
})
local command_legend_menu = sol.modules.get_object("trilmenu_component_command_legend").new(command_legend_defaults)

local options_list = {
  "continue",
  "save_and_quit"
}

local allowed_objects = {}
for _, option in pairs(options_list) do
  local object = {}
  object.name = option
  object.text_config = {text_key = "menu.pause." .. option}
  object.text_offset = {x = 16, y = 12}
  table.insert(allowed_objects, object)
end

local config = {
  allowed_objects = allowed_objects,
  origin = {x = 32, y = 48},
  grid_size = {columns=1, rows = 5},
  cell_size = {width=160, height=24},
  cell_spacing = 4,
  edge_spacing = 4,
  cell_png = "menus/menu_choice_cell.png",
  cursor_style = "menus/arrow",
  cursor_offset = {x=4, y=8},
  cursor_sound = "cursor",
  aux_menus = { command_legend_menu },
}

local menu = sol.modules.get_object("trilmenu_grid").create(config)

menu:register_event("on_command_pressed", function(menu, command, controls_ob)
  local handled = false
  if command == "confirm" then
    local selection = menu:get_selected_object().name
    menu:process_selection(selection)
    handled = true
  end
  return handled
end)


function menu:process_selection(selection)
  local game = sol.main.get_game()
  if selection == "continue" then
    game:set_paused(false)

  elseif selection == "save_and_quit" then
    game:start_dialog("system.save_and_quit_question", function(answer)
      if answer == 1 then
        game:save()
        sol.timer.start(game, 100, function()
          sol.main.reset()
        end)
      end
    end)

  end
end

return menu
