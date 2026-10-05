--The purpose of this menu to is to handle switching out submenus, as well as keeping controls input processing/interpretation in one place (as it can be a little weird before the game starts)

local multi_events = sol.modules.get_object("multi_events")

local top_menu = {}
local current_submenu
multi_events:enable(top_menu)

function top_menu:on_started()
  --Start a background
  sol.menu.start(top_menu, require"scripts/menus/title_screen/background", false)

  --Start the first title screen menu and set top menu as its parent
  local first_menu = require"scripts/menus/title_screen/press_any_button"
  if sol.menu.is_started(first_menu) then return end
  sol.menu.start(top_menu, first_menu)
  top_menu:set_current_submenu(first_menu)
end

function top_menu:set_current_submenu(new_menu)
  current_submenu = new_menu
  new_menu.top_menu = top_menu
end


local ALLOWED_COMMANDS = {
  down = true,
  up = true,
  action = true,
  attack = true,
  item_1 = true,
  item_2 = true,
  pause = true,
}


----COMMAND---------------------------------------------------------------------
top_menu:register_event("on_command_pressed", function(self, command, controls_ob)
  return current_submenu:process_input(command)
end)


---KEYBOARD---------------------------------------------------------------

top_menu:register_event("on_key_pressed", function(self, key)
  local command
  --Make return always be "action" in the title screen, since players haven't yet set keybinds
  if key == "return" then
    command = "action" --print("Return key pressed, swapped command to 'action'")
  end
  if ALLOWED_COMMANDS[command] then return current_submenu:process_input(command) end
end)


--Avoid analog stick wildly jumping
if sol.main.old_controls_version then
  local joy_avoid_repeat = {-2, -2}
  local first_joypress = true

  function top_menu:on_joypad_axis_moved(axis,state)
    local handled = joy_avoid_repeat[axis % 2] == state
    joy_avoid_repeat[axis % 2] = state

    if handled or first_joypress then
      first_joypress = false
      return
    end

    if top_menu.joypad_just_moved then return end

    local command
    if ALLOWED_COMMANDS[command] then
      top_menu.joypad_just_moved = true
      sol.timer.start(sol.main, 20, function() top_menu.joypad_just_moved = false end)
      return current_submenu:process_input(command)
    end
  end
end


return top_menu
