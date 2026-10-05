--[[
Controls Manager
Created by Max Mraz, licensed MIT
Sets up defaults controls for Solarus 2.0+ games. Note: This is designed for single-player games.

Requirements:
Dialog at "system.controls.joypad_disconnect" that says something like "Controller Disconnected!" -- this will be called in a controller disconnect event, counting on dialogs to pause the game

Functions you may want too use:

sol.controls.get_controls_manager() --gets this manager
sol.controls.get_main_controls() --gets main controls object
manager.get_joypad_type() --returns which console the controller belongs to. Possible values are "xbox", "playstation", "switch", or "generic"
manager.get_active_input_type() --Returns either "keyboard" or "joypad"
manager:get_command_sprite_id(command) --Get the sprite ID and animation for a given command, accounting for active input type. Return: sprite_id (string), animation (string)
controls_object.get_angle() --Returns the currently held angle of the Axis stick. TBH, I don't remember if this is the left or right stick, I think the right.
--]]

--This won't work under Solarus 2.0, error if you try to call it
if tonumber(sol.main.get_solarus_version():match("(%d+.%d+)")) < 2.0 then
  print("Warning: Cannot use controls manager with Solarus version < 2.0")
  return
end

local manager = {}
local file_io = sol.file_io
local settings = sol.modules.get_object("settings_manager")

--Config related things:
--Default controls table
local default_controls = require("scripts/modules/trillium_config/controls/default_controls")
local default_controls_switch = require("scripts/modules/trillium_config/controls/default_controls_switch")
local disconnect_menu = require("scripts/modules/trillium/core/controls/menus/controller_disconnect")
--Name of the remapping file that will be saved/read to the savegame directory:
local control_file = "control_mapping.dat"

--Disable legacy joypad support:
sol.input.set_joypad_enabled(false)


--Returns controls manager
function sol.controls.get_controls_manager()
  return manager
end

--Returns main controls object
function sol.controls.get_main_controls()
  return sol.main.main_controls
end


function sol.controls.set_main_controls(control_ob)
  sol.main.main_controls = control_ob
end


function manager.init()
  print("Info: Initializing controls manager")
  manager.load_default_controls()
  manager.create_controls()
  manager.load_keyboard_mapping_from_settings()
end


function manager.load_keyboard_mapping_from_settings()
  if settings then
    local kb_style = settings.get_value("keyboard_controls_style")
    manager.load_keyboard_mapping_set(kb_style or "keyboard")
  end
end


function sol.controls.get_main_controls()
  return sol.main.main_controls
end


function manager.load_default_controls(force, override_file)
  if not sol.file.exists(control_file) or (force == true) then
    print("Info: Loading default controls")
    local data = default_controls
    --Check OS, swap default file if needed
    local os_default = manager.check_os_default()
    if os_default then data = os_default end
    if override_file then data = require(override_file) end
    file_io.write_table(data, control_file)
  end
end


function manager.check_os_default()
  local os = sol.main.get_os():lower()
  if os:match("switch") then
    --Older SDL verion sent the bottom face button as A no matter what. Newer version seems to correctly send B on Switch controllers
    --So this special control should be unnecessary:
    --return default_controls_switch
  end
end


function manager.reset_default_controls()
  print("Debug: Resetting to default controls")
  manager.load_default_controls(true)
  local active_joypad = sol.main.main_controls.joypad
  manager.create_controls(active_joypad)
end


function manager.create_controls(joypad)
  --Remove any old controls:
  if sol.main.main_controls then sol.main.main_controls:remove() print"Debug: Removing old main controls" end

  joypad = joypad or sol.input.get_joypads()[1]
  if joypad then
    sol.main.main_controls = sol.controls.create_from_joypad(joypad)
    sol.controls.set_analog_commands_enabled(true)
    sol.main.main_controls.joypad = joypad
    sol.main.main_controls.active_device = joypad
  else
    sol.main.main_controls = sol.controls.create_from_keyboard()
    sol.controls.set_analog_commands_enabled(false)
    sol.main.main_controls.active_device = "keyboard"
  end

  manager.load_control_mapping()
end


function manager.load_control_mapping()
  local data = file_io.read_table(control_file)
  --Joypad buttons:
  sol.main.main_controls:set_joypad_bindings(data.joypad)
  --Joypad axis:
    sol.main.main_controls:set_joypad_axis_bindings(data.joypad_axis)
  --Keyboard:
  sol.main.main_controls:set_keyboard_bindings(data.keyboard)
  --TODO: mouse?
end


function manager.load_keyboard_mapping_set(set_id)
  --Controls data will have control bindings for "joypad", "joypad_axis", and "keyboard"
  --But it can also have other keyboard sets in the data as well, such as "kbm" for keyboard and mouse
  local data = file_io.read_table(control_file)
  assert(data[set_id])
  sol.main.main_controls:set_keyboard_bindings(data[set_id])
end


function manager.get_control_data_from_current_controls()
  local controls = sol.main.main_controls
  local joypad_bindings = controls:get_joypad_bindings()
  local joypad_axis_bindings = controls:get_joypad_axis_bindings()
  local keyboard_bindings = controls:get_keyboard_bindings()
  local data = {
    joypad = joypad_bindings,
    joypad_axis = joypad_axis_bindings,
    keyboard = keyboard_bindings,
  }
  return data
end


function manager.save_controls()
  local data = manager.get_control_data_from_current_controls()
  file_io.write_table(data, control_file)
end


--These functions are called when keyboard or joypad input is pressed, makes any changes necessary to hotswap to other control device:
function manager.activate_keyboard()
  if sol.main.main_controls.active_device == "keyboard" then return end --skip if keyboard already active
  -- print("Debug: Activating keyboard controls")
  sol.main.main_controls.active_device = "keyboard"
  sol.main.main_controls.joypad = nil
  --Disable analog controls for some reason this causes Left/Right to move the player in reverse
  sol.controls.set_analog_commands_enabled(false)
end


function manager.activate_joypad(joypad)
  if (sol.main.main_controls.active_device == joypad) and (sol.main.main_controls.joypad == joypad) then return end --skip if this joypad is already active
  -- print("Debug: Activating joypad controls")
  sol.timer.start(sol.main, 10, function()
    joypad:rumble(0, .5, 200)
  end)
  sol.main.main_controls:set_joypad(joypad)
  sol.main.main_controls.active_device = joypad
  sol.main.main_controls.joypad = joypad
  manager.alert_on_joypad_disconnect(joypad)
  --Enable analog controls, causes some bug with left/right movement on keyboard when enabled
  sol.controls.set_analog_commands_enabled(true)
end


--When keyboard/joypad input is detected, active the corresponding input type:
sol.main:register_event("on_key_pressed", function(self, key)
  manager.activate_keyboard()
end)

sol.main:register_event("on_mouse_pressed", function(self, button, x, y)
  manager.activate_keyboard()
end)

sol.main:register_event("on_mouse_released", function(self, button, x, y)
  manager.activate_keyboard()
end)

sol.main:register_event("on_joypad_button_pressed", function(_, button, joypad)
  manager.activate_joypad(joypad)
end)

sol.main:register_event("on_joypad_axis_moved", function(_, axis, state, joypad)
  manager.activate_joypad(joypad)
end)

function sol.input:on_joypad_connected(joypad)
  manager.activate_joypad(joypad)
end


--Alert when joypad is disconnected:
function manager.alert_on_joypad_disconnect(joypad)
  function joypad:on_removed()
    local game = sol.main.get_game()
    if game and not game:is_suspended() then
      game:set_suspended(true)
      function disconnect_menu:on_finished()
        game:set_suspended(false)
      end
    else
      disconnect_menu.on_finished = nil
    end
    sol.menu.start(sol.main, disconnect_menu)
  end
end


--Set game and hero controls to read from main controls:
function manager.set_game_controls()
  local game = sol.main.get_game()
  if game then
    print("Info: Setting game controls")
    local hero = game:get_hero()
    game:get_controls():remove()
    hero:get_controls():remove()
    game:set_controls(sol.main.main_controls)
    hero:set_controls(sol.main.main_controls)
    --print("--------------------")
  end
end


--Game metatable:
local game_meta = sol.main.get_metatable"game"
game_meta:register_event("on_started", function(game)
  manager.set_game_controls()
end)



--Functions for other systems to call:

--Returns which console the controller belongs to, useful for displaying the appropriate button sprites:
--Possible values are "xbox", "playstation", "switch", or "generic"
function manager.get_joypad_type()
  local controls_ob = sol.controls.get_main_controls()
  if not controls_ob.joypad then
    return nil
  end
  local name = controls_ob.joypad:get_name() or "unknown_controller"
  name = name:lower()
  if name:match("xbox") then
    return "xbox"
  elseif name:match("playstation") or name:match("dualsense") or name:match("dualshock") or name:match("ps4") or name:match("ps5") then
    return "playstation"
  elseif name:match("switch") or name:match("joy%-con") then
    return "switch"
  else
    return "generic"
  end
end


--Helper function to make sure a table contains an element, useful to check if a binding contains a command
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end


--Additive command binding: adds the command to the binding, does not overwrite:
function manager.add_binding(command, input, control_type)
  assert(control_type == "joypad" or control_type == "joypad_axis" or control_type == "keyboard", "Invalid control type passed: " .. control_type)
  local controls = sol.main.main_controls
  local data = manager.get_control_data_from_current_controls()
  table.insert(data[control_type][input], command)
  --Update controls object:
  if control_type == "joypad" then
    controls:set_joypad_bindings(data[control_type])
  elseif control_type == "joypad_axis" then
    controls:set_joypad_axis_bindings(data[control_type])
  elseif control_type == "keyboard" then
    controls:set_keyboard_bindings(data[control_type])
  end
  --Validate joypad:
  assert(table.contains(controls:get_joypad_bindings()[input], command), "Command " .. command .. " failed to bind to input " .. input)
end


--Unbinds command from all current bindings, without affecting other commands bound to that input:
function manager.remove_binding(command, control_type)
  assert(control_type == "joypad" or control_type == "joypad_axis" or control_type == "keyboard", "Invalid control type passed: " .. control_type)
  local controls = sol.main.main_controls
  local bindings = {}
  if control_type == "joypad" then
    bindings = controls:get_joypad_bindings()
  elseif control_type == "joypad_axis" then
    bindings = controls:get_joypad_axis_bindings()
  elseif control_type == "keyboard" then
    bindings = controls:get_keyboard_bindings()
  end
  --Remove selected command
  for binding, cmds in pairs(bindings) do
    for i, cmd in ipairs(cmds) do
      if cmd == command then
        --bindings[binding][i] = nil
        table.remove(bindings[binding], i)
      end
    end
  end
  --Update controls object:
  if control_type == "joypad" then
    controls:set_joypad_bindings(bindings)
  elseif control_type == "joypad_axis" then
    controls:set_joypad_axis_bindings(bindings)
  elseif control_type == "keyboard" then
    controls:set_keyboard_bindings(bindings)
  end
end


--Overwrites for the :get_binding(command) methods. They don't work with :set_bindings(table) methods
--TODO: perhaps the engine will handle this
local controls_meta = sol.main.get_metatable("controls")

function controls_meta:get_joypad_binding(command)
  local all_inputs = {}
  local bindings = self:get_joypad_bindings()
  for input, commands in pairs(bindings) do
    for _, cmd in ipairs(commands) do
      if cmd == command then
        table.insert(all_inputs, input)
      end
    end
  end
  --For now, only return the first binding:
  return all_inputs[1]
end

function controls_meta:get_keyboard_binding(command)
  local all_inputs = {}
  local bindings = self:get_keyboard_bindings()
  for input, commands in pairs(bindings) do
    for _, cmd in ipairs(commands) do
      if cmd == command then
        table.insert(all_inputs, input)
      end
    end
  end
  --For now, only return the first binding:
  return all_inputs[1]
end



--Returns the angle of the X and Y axis
function controls_meta:get_angle()
  local controls = self
  local x, y = controls:get_axis_state("X"), controls:get_axis_state("Y")
  --Make sure the stick is actually pressed:
  if x == 0 and y == 0 then
    return nil
  end
  local angle = math.atan2(y * -1, x)
  return angle
end


--Get active input type:
--Returns either "keyboard" or "joypad"
function manager.get_active_input_type()
  if  sol.main.main_controls.active_device == "keyboard" then
    return "keyboard"
  else
    return "joypad"
  end
end


--Get the sprite ID and animation for a given command, accounting for active input type
--Return: sprite_id (string), animation (string)
function manager:get_command_sprite_id(command)
  local game = sol.main.get_game()
  local controls_ob = sol.controls.get_main_controls()
  local sprite_id
  local animation
  local command_display_style = manager.get_active_input_type()

  if command_display_style == "joypad" then
    local button_name = controls_ob:get_joypad_binding(command):gsub(" %+", ""):gsub(" %-", "")
    local joypad_type = manager.get_joypad_type() or "generic"
    sprite_id = "hud/button_icons/" .. joypad_type
    animation = button_name

  elseif command_display_style == "keyboard" then
    local key = controls_ob:get_keyboard_binding(command):gsub(" ", "_")
    sprite_id = "hud/button_icons/keyboard"
    animation = key

  else --default to keyboard/mouse display:
    local key = controls_ob:get_keyboard_binding(command):gsub(" ", "_")
    if command == "attack" then key = "mouse_left"
    elseif command == "aim" then key = "mouse_right"
    end
    sprite_id = "hud/button_icons/keyboard"
    animation = key

  end

  return sprite_id, animation
end




manager.init()
