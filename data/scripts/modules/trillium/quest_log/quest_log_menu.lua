local quest_ids = require("scripts/modules/trillium_config/world_data/logged_quests")
local all_ids = {}
for _, id in pairs(quest_ids.main) do table.insert(all_ids, id) end
for _, id in pairs(quest_ids.side) do table.insert(all_ids, id) end



local function generate_menu_object(quest_dto)
  --Take a quest log DTO and generate an object the menu system can read
  local object = {}
  local quest_id = quest_dto.id
  local state = quest_dto.state
  object.name = quest_id
  object.text_config = {
    text_key = "quest_log." .. quest_id,
    color = state == "completed" and {150,150,150} or sol.colors.ui_ink
  }
  object.text_offset = {x = 16, y = 8}
  --object.description_name_string = "quest_log." .. quest_id
  object.description_dialog = "quest_log." .. quest_id
  object.display_function = function()
    local game = sol.main.get_game()
    local phase = game:get_quest_phase(quest_id)
    return phase ~= nil
  end
  return object
end

local function generate_allowed_objects(active_quests_dto)
  --Generate a table of menu objects for all active quests
  local allowed_objects = {}
  for _, quest_dto in ipairs(active_quests_dto.main) do
    table.insert(allowed_objects, generate_menu_object(quest_dto))
  end
  for _, quest_dto in ipairs(active_quests_dto.side) do
    table.insert(allowed_objects, generate_menu_object(quest_dto))
  end
  for _, quest_dto in ipairs(active_quests_dto.main_completed) do
    table.insert(allowed_objects, generate_menu_object(quest_dto))
  end
  for _, quest_dto in ipairs(active_quests_dto.side_completed) do
    table.insert(allowed_objects, generate_menu_object(quest_dto))
  end

  return allowed_objects
end


local allowed_objects = {} --will populate this at menu start time to have access to game object

local config = {
  allowed_objects = allowed_objects,
  origin = {x = 16, y = 28},
  background_offset = {x = 0, y = 2},
  background_9slice_config = {
    width = 240, height = 176,
    source_png = "menus/panel_blocks/journal.png",
  },
  grid_size = {columns=1, rows=8},
  cell_size = {width=128, height=18},
  cell_spacing = 4,
  edge_spacing = 4,
  --cell_png = "menus/checkpoint/choice_cell.png",
  cursor_style = "menus/arrow",
  cursor_offset = {x=4, y=5},
  cursor_sound = "cursor",
}

--Show description panel
local description_panel_config = table.duplicate(require("scripts/menus/inventory/item_description_panel_config"))
description_panel_config.text_surface_y_offset = 16
description_panel_config.background_png = "menus/inventory/description_panel_background_no_line.png"
local description_panel = sol.modules.get_object("trilmenu_description_panel").create(description_panel_config)
local command_legend = sol.modules.get_object("trilmenu_component_command_legend").new({
  commands = {
    { command = "cancel",  action = "menu.actions.exit"},
  },
  x = 48, y = 220,
})
config.aux_menus = { description_panel, command_legend }

local menu = sol.modules.get_object("trilmenu_grid").create(config)


menu:register_event("on_started", function()
  local game = sol.main.get_game()
  menu.allowed_objects = generate_allowed_objects(game:get_active_quests())
  menu:update_objects()
end)

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
  if submenus[selection] then
    local submenu = submenus[selection]
    sol.menu.stop(self)
    submenu.parent_menu = self
    sol.menu.start(game, submenu)

  end
end


return menu

