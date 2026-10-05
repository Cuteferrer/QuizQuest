--[[
Created by Max Mraz, licensed MIT

Example: you interact with a shopkeeper, who also may have information to share
This script can start a menu with choices such as "Shop", "About the forest...", "Give quest item", etc
Each option's presence can be dependent on any factors, and will trigger its own callback


--]]

local game_meta = sol.main.get_metatable("game")

--Config for how the conversation choices should look:
local layout_config = {
  origin = {x = 48, y = 32},
  background_offset = {x = 0, y = -6},
  grid_size = {columns=1, rows=6},
  cell_size = {width=400, height=18},
  cell_spacing = 4,
  edge_spacing = 4,
  --background_png = "menus/inventory/options_background.png",
  cell_png = "menus/dialog_choice_cell.png",
  cursor_style = "menus/arrow",
  cursor_offset = {x=4, y=5},
  cursor_sound = "cursor",
}


--Start Conversation Menu:
--[[
game:start_conversation_menu(choices)

Pass in some table like:
{
  {
    choice_string = "dialog.choices.npc.amos.bounty_hunter", --this will be the text on the choice
    display_function = function() return game:get_value("talked_to_bounty_hunter") end, --a function that returns true or false, indicating whether to show this choice. If absent, the choice will always show
    callback = function() end OR "some_dialog_id", --either a function to be called when the option is selected, or a dialog ID to show when selected
  },
  {
    choice_string = "some_string",
    display_function = function()
      return true
    end,
    callback = "some_other_dialog_id",
  },
}

Callbacks: callbacks are called, passing the menu as an argument: choice.callback(menu)


REMEMBER TO PASS IN AN "EXIT" CHOICE THAT STOPS THE MENU!
--]]
function game_meta:update_conversation_menu()
  local game = self
  local menu = game.active_conversation_menu
  if menu then
    menu:update_objects()
    --Manually move the cursor if the update shrunk the displayed items and the cursor is outside the valid choices:
    if menu.cursor_index > #menu.displayed_objects then
      menu.cursor_index = #menu.displayed_objects
      menu:update_surface()
    end
  end
end

function game_meta:start_conversation_menu(choices)
  local game = self
  --Set config:
  local config = table.duplicate(layout_config)

  --Go through choices to put them into the menu if they're available:
  local allowed_objects = {}
  for _, choice in pairs(choices) do
    local object = {}
    object.display_function = choice.display_function
    object.text_config = {text_key = choice.choice_string}
    object.text_offset = {x = 16, y = 8}
    --Set callback depending if it's a string or a function
    if choice.callback == "exit" then
      object.callback = function(menu)
        sol.menu.stop(menu)
      end
    elseif type(choice.callback) == "string" then
      object.callback = function(menu)
        game:start_dialog(choice.callback, function()
          game:update_conversation_menu()
        end)
      end
    else
      object.callback = function(menu)
        choice.callback(menu)
        game:update_conversation_menu()
      end
    end
    table.insert(allowed_objects, object)
  end
  config.allowed_objects = allowed_objects

  --Decoration above menu:
  local filigree_decoration = {}
  local filigree_texture = sol.surface.load("sprites/menus/decoration/filigree_choices.png")
  function filigree_decoration:on_draw(dst)
    filigree_texture:draw(dst, 16, 16)
  end
  function filigree_decoration:notify() end
  config.aux_menus = { filigree_decoration }

  --Make a conversation menu:
  menu = sol.modules.get_object("trilmenu_grid").create(config)
  game.active_conversation_menu = menu

  menu:register_event("on_command_pressed", function(menu, command)
    local handled = false
    if command == "confirm" then
      local choice = menu:get_selected_object()
      choice.callback(menu)
      handled = true
    end
    return handled
  end)

  menu:register_event("on_started", function()
    game:set_suspended(true)
  end)

  menu:register_event("on_finished", function()
    game:set_suspended(false)
  end)

  --Hide HUD when open:
  menu:hide_hud_when_open()

  sol.menu.start(game:get_map(), menu)
end



