--[[
Created by Max Mraz, licensed MIT
A button binding menu to work with Solarus 1.7 controls
--]]

local menu = {}
local controls_manager = sol.controls.get_controls_manager()
sol.modules.get_object("multi_events"):enable(menu)

local input_capture_warning = require("scripts/modules/trillium/core/controls/menus/input_capture_warning")
local is_console = sol.main.get_build_conf().console or false
menu.cursor_index = 1

--Config
local panel_size = {width = 256, height = 24}
local panel_padding = 4
local font, font_size = sol.modules.get_object("language_manager"):get_dialog_font()
local command_area_size = {width = 320, height = 196}
local cursor_x_offset = 16


local command_set_ids = {
  "joypad",
  "keyboard",
}
if is_console then
command_set_ids = {
  "joypad",
} 
end
menu.command_set = command_set_ids[1]

--Include all commands here:
local command_sets = {
  joypad = {
    "action", "attack", "aim", "dodge", "fire", "item_1", "item_2", "pause",
    "weapon_art", "wraithshot", "hookshot", "map",
    --"movement_stick", "aim_stick",
    "quickswap_melee", "quickswap_gun", "quickswap_item_2", "quickswap_item_1",
  },

  keyboard = {
    "action", "attack", "aim", "dodge", "fire", "item_1", "item_2", "pause",
    "weapon_art", "wraithshot", "hookshot", "map",
    "up", "down", "left", "right",
    "quickswap_melee", "quickswap_gun", "quickswap_item_2", "quickswap_item_1",
  },
}

--Disallow these buttons from being bound to commands:
local forbidden_inputs = {
  escape = true,
  f1 = true,
  f11 = true,
  ['left meta'] = true,
  ['right meta'] = true,
  ['\\'] = true,
  ["up"] = true,
  ["down"] = true,
  ["left"] = true,
  ["right"] = true,
  ["right_y +"] = true,
  ["right_y -"] = true,
  ["right_x +"] = true,
  ["right_x -"] = true,
  ["left_y +"] = true,
  ["left_y -"] = true,
  ["left_x +"] = true,
  ["left_x -"] = true,
}

--Disallow these commands from being re-bound - NOTE: I don't recommend this, but the script can't handle control axis yet I don't think
local forbidden_commands = {
  movement_stick = true,
  aim_stick = true,
}


menu.background = sol.surface.create()
menu.background:fill_color{0,0,0,200}
menu.working_surface = sol.surface.create()
menu.window_surface = sol.surface.create(command_area_size.width, command_area_size.height)
--Type selector:
menu.type_selector_border = sol.surface.create(panel_size.width, panel_size.height)
menu.type_selector_background = sol.surface.create(panel_size.width - 2, panel_size.height - 2)
menu.type_selector_text = sol.text_surface.create{
  font = font, font_size = font_size
}
menu.type_selector_arrow = sol.sprite.create"menus/arrows_wide"

local cursor = sol.sprite.create("menus/arrow")


function menu:update_panel(panel)
  --Takes a panel object, which has a command on it. Stamps the assigned button/key icon on it
  local command = panel.command
  local controls_ob = sol.controls.get_main_controls()
  --Get bindings
  local joypad_binding = controls_ob:get_joypad_binding(command)
  local keyboard_binding = controls_ob:get_keyboard_binding(command)
  if menu.command_set == "joypad" and joypad_binding ~= nil then
    --Controller button icon:
    joypad_binding = joypad_binding:gsub("%s.*", "")
    local joypad_type = controls_manager.get_joypad_type() or "generic"
    local sprite = sol.sprite.create("hud/button_icons/" .. joypad_type)
    if not sprite:has_animation(joypad_binding) then
      print("Warning: binding '" .. joypad_binding .. "' is assigned to command '" .. command .. "', but was not found in sprite!")
      sprite:set_animation("unknown")
    else
      sprite:set_animation(joypad_binding)
    end
    sprite:draw(panel.background, panel_size.width - 24, panel_size.height - 11)
  elseif menu.command_set == "keyboard" and keyboard_binding ~= nil then
    keyboard_binding = keyboard_binding:gsub("%s", "_")
    local sprite = sol.sprite.create("hud/button_icons/keyboard")
    if sprite:has_animation(keyboard_binding) then
      sprite:set_animation(keyboard_binding)
    else
      sprite:set_animation("unknown_key")
    end
    sprite:draw(panel.background, panel_size.width - 24, panel_size.height - 11)
  end
  return panel
end


function menu:update_commands()
  menu.num_commands = #command_sets[menu.command_set]
  menu.panel_surface = sol.surface.create(command_area_size.width, (panel_size.height + panel_padding) * (menu.num_commands + 3))
  menu.panel_surface:fill_color{20,20,20,200}--temp? Maybe?
  --Also create a working surface: the command surface as well as the cursor are drawn here, so the cursor can move around
  menu.working_surface = sol.surface.create(command_area_size.width, (panel_size.height + panel_padding) * (menu.num_commands + 3))
  --These next two will move the cursor back to the top, which is annoying, so we'll need to later figure out how to not scroll the surface when recreating it
  menu.working_surface.y = 0
  menu.cursor_index = 1
  menu.active_commands = {}
  menu.command_panels = {}
  for i, command in ipairs(command_sets[menu.command_set]) do
    menu.active_commands[i] = command
    local panel = {}
    panel.command = command
    panel.background = sol.surface.create(panel_size.width, panel_size.height)
    panel.background:fill_color{100,100,100,255}
    panel.text_surface = sol.text_surface.create{
      font = font, font_size = font_size,
      text_key = "options.command." .. command,
    }
    panel = menu:update_panel(panel)

    panel.text_surface:draw(panel.background, 16, panel_size.height - 11)
    panel.background:draw(menu.panel_surface, command_area_size.width / 2 - panel_size.width / 2 , panel_padding + i * (panel_size.height + panel_padding))
    menu.command_panels[i] = panel
  end

  menu:update_working_surface()
end


function menu:update_working_surface()
  menu.window_surface:clear()
  menu.working_surface:clear()
  menu.panel_surface:draw(menu.working_surface)
  cursor:draw(menu.working_surface, cursor_x_offset, menu.cursor_index * (panel_size.height + panel_padding) + panel_size.height / 2)
  menu.working_surface:draw(menu.window_surface, 0, menu.working_surface.y or 0)
end


function menu:update_type_selector()
  menu.type_selector_border:clear()
  if #command_set_ids <= 1 then return end --don't show type selector if there's only one type of controls
  menu.type_selector_text:set_text(sol.language.get_string("menu.controls.control_set") .. " " .. sol.language.get_string("menu.controls." .. menu.command_set))
  menu.type_selector_background:clear()
  menu.type_selector_border:fill_color({140, 130, 125, 255})
  menu.type_selector_background:fill_color{0, 0, 0, 200}
  menu.type_selector_background:draw(menu.type_selector_border, 1, 1)
  menu.type_selector_text:draw(menu.type_selector_border, 32, panel_size.height / 2)
  menu.type_selector_arrow:set_animation"arrow_left"
  menu.type_selector_arrow:draw(menu.type_selector_border, 16, panel_size.height / 2 - 4)
  menu.type_selector_arrow:set_animation"arrow_right"
  menu.type_selector_arrow:draw(menu.type_selector_border, panel_size.width - 16, panel_size.height / 2 - 4)
end


function menu:move_cursor(direction)
  local step = 1
  if direction == "up" then step = -1 end
  menu.cursor_index = menu.cursor_index + step
  if menu.cursor_index > #command_sets[menu.command_set] then
    menu.cursor_index = #command_sets[menu.command_set]
  elseif menu.cursor_index < 1 then
    menu.cursor_index = 1
  end

  menu:update_working_surface()
  menu:check_to_scroll(direction)
end


function menu:check_to_scroll(direction, skip_to)
  local function scroll_it()
    local m = sol.movement.create"straight"
    m:set_angle(3 * math.pi / 2)
    if direction == "down" then m:set_angle(math.pi / 2) end
    m:set_max_distance(panel_size.height + panel_padding)
    m:set_speed(300)
    m:start(menu.working_surface)
    function m:on_position_changed()
      menu:update_working_surface()
    end
  end

  local cursor_height = menu.cursor_index * (panel_size.height + panel_padding)
  local scroll_limit_min = direction == "down" and 3 or 2
  local scroll_limit_max = direction == "up" and 2 or 1
  local num_commands = #command_sets[menu.command_set]
  if (menu.cursor_index - scroll_limit_min > 0) and (num_commands - menu.cursor_index > scroll_limit_max) then
    scroll_it()
  end
end


function menu:change_control_type(direction)
  local current_i = 1
  for i, v in ipairs(command_set_ids) do
    if v == menu.command_set then
      current_i = i
    end
  end
  local new_i = current_i + (1 * direction)
  if new_i > #command_set_ids then new_i = 1 end
  if new_i <= 0 then new_i = #command_set_ids end
  sol.audio.play_sound("cursor")
  menu.command_set = command_set_ids[new_i]
  menu.cursor_index = 1
  menu:update_type_selector()
  menu:update_commands()
  menu:update_working_surface()
end


function menu:on_command_pressed(command, controls_ob)
  local handled = false
  
  if menu.active_input_capture then
    error("This menu should never receive commands while listing for inputs, they should be captured and handled to rebind")
    handled = false

  elseif sol.menu.is_started(input_capture_warning) then
    sol.menu.stop(input_capture_warning)
    handled = true

  elseif command == "up" or command == "down" then
    menu:move_cursor(command)
    handled = true

  elseif command == "confirm" and not menu.active_input_capture then
    menu:listen_for_input()
    handled = true

  elseif (command == "pause" or command == "cancel") then
    sol.menu.stop(menu)
    handled = true

  elseif command == "left" or command == "submenu_left" then
    menu:change_control_type(-1)
    handled = true

  elseif command == "right" or command == "submenu_right" then
    menu:change_control_type(1)
    handled = true

  end

  return handled
end


--[[Reworking this. As is, if this rebinding menu is in the context of a different menu (so, it's a submenu on top of an options menu)
and that other menu defines on_key_pressed (or button), all key_press events propogate down before commands are read.
Basically, input gets sent down the menu chain and handled before it gets a chance to hit the "commands" layer -- Which is also the CONTROLS OBJECT LAYER
So controls:capture_bindings() will never hear certain inputs, if they're handled by on_key_press events before it gets a chance.
Gonna try to rewrite it so the menu doesn't use capture_bindings() at all, but triggers right on on_key_pressed so it can never be bypassed
--]]
--[[
function menu:listen_for_input()
  sol.audio.play_sound"danger"
  menu.active_input_capture = true
  menu.input_adapter_bypass = true
  if menu.invalid_input_message_timer then menu.invalid_input_message_timer:stop() end
  sol.menu.start(menu, input_capture_warning)
  local selected_command = menu.command_panels[menu.cursor_index].command
  --Check that command can be rebound
  if forbidden_commands[selected_command] then
    input_capture_warning:invalid_command()
    return
  end

  print("capturing binding for", selected_command)
  local controls_ob = sol.controls.get_main_controls()
  local old_keyboard_binding = controls_ob:get_keyboard_binding(selected_command)
  local old_joypad_binding = controls_ob:get_joypad_binding(selected_command)
  controls_ob:capture_bindings(selected_command, function()
  --Check new command and binding - if it's invalid, reset it to how it was
    local new_keyboard_binding = controls_ob:get_keyboard_binding(selected_command)
    local new_joypad_binding = controls_ob:get_joypad_binding(selected_command)
    if forbidden_inputs[new_keyboard_binding] or forbidden_inputs[new_joypad_binding] then
      --Invalid Input! Roll back changes
      sol.audio.play_sound"wrong"
      controls_ob:set_keyboard_binding(selected_command, old_keyboard_binding)
      controls_ob:set_joypad_binding(selected_command, old_joypad_binding)
      input_capture_warning:invalid_input()
      menu.invalid_input_message_timer = sol.timer.start(menu, 3000, function()
        if sol.menu.is_started(input_capture_warning) then
          sol.menu.stop(input_capture_warning)
        end
      end)
    else
      --Valid Input:
      sol.audio.play_sound"ok"
      sol.menu.stop(input_capture_warning)
    end
    menu.active_input_capture = false
    menu.input_adapter_bypass = false
    --Save new bindings:
    controls_manager.save_bindings()
    menu:update_commands()
  end)
end
--]]


function menu:listen_for_input()
  sol.audio.play_sound"danger"
  if menu.invalid_input_message_timer then menu.invalid_input_message_timer:stop() end
  sol.menu.start(menu, input_capture_warning)
  menu.active_input_capture = true
end


function menu:on_key_pressed(key)
  if menu.active_input_capture then
    menu:bind_command("keyboard", key)
    return true
  end
end

function menu:on_joypad_button_pressed(button)
  local handled = false
  if menu.active_input_capture then
    menu:bind_command("joypad", button)
    handled = true
  end
  return handled
end

function menu:on_joypad_axis_moved(axis, state, joypad)
  if menu.active_input_capture then
    --Hardcoded: disallow left and right sticks for rebinding:
    if axis:match("left_x") or axis:match("left_y") or axis:match("right_x") or axis:match("right_y") then
      return true
    end
    axis = axis .. " +" --Axis binds will be for the triggers, so we can assume it's the + direction we want to bind lol
    menu:bind_command("joypad", axis)
    return true
  end
end


local function show_invalid_input()
  menu.invalid_input_message_timer = sol.timer.start(menu, 3000, function()
    if sol.menu.is_started(input_capture_warning) then sol.menu.stop(input_capture_warning) end
  end)
  menu.active_input_capture = false
end


local function validate_command_bound(controls_ob, selected_command)
  local bound = true
  if (controls_ob:get_keyboard_binding(selected_command) == nil) then
    bound = false
  end
  if (controls_ob:get_joypad_binding(selected_command) == nil) and (selected_command ~= "up") and (selected_command ~= "down") and (selected_command ~= "left") and (selected_command ~= "right") then
    bound = false
  end

  return bound
end


function menu:update_controls_with_new_binding(control_type, new_input, new_command)
  local controls_ob = sol.controls.get_main_controls()

  local updated_bindings = control_type == "keyboard" and controls_ob:get_keyboard_bindings() or controls_ob:get_joypad_bindings()
  --Remove previous binding
  for input, old_commands in pairs(updated_bindings) do
    local updated_commands = {}
    for _, cmd in ipairs(old_commands) do
      if cmd ~= new_command then
        table.insert(updated_commands, cmd)
      else
        --print("Rebinding step: Removing command ", cmd, "from input ", input)
      end
    end
    updated_bindings[input] = updated_commands
  end
  --Add new command to bindings
  if not updated_bindings[new_input] then updated_bindings[new_input] = {} end --if this input has not been bound already
  table.insert(updated_bindings[new_input], new_command)

  --Set updated bindings to control ob
  if control_type == "keyboard" then
    controls_ob:set_keyboard_bindings(updated_bindings)
  elseif control_type == "joypad" then
    controls_ob:set_joypad_bindings(updated_bindings)
  end

  --Save new bindings to dat file:
  controls_manager.save_controls()
  --Reset game controls if a game is running
  if sol.main.get_game() then
    controls_manager.set_game_controls()
  end
  menu:update_commands()
  sol.audio.play_sound"ok"
  sol.menu.stop(input_capture_warning)
  menu.active_input_capture = false
end


function menu:bind_command(control_type, input)
  assert(control_type == "joypad" or control_type == "keyboard", "Invalid control type passed")
  local controls_ob = sol.controls.get_main_controls()
  local selected_command = menu.command_panels[menu.cursor_index].command
  local old_keyboard_binding = controls_ob:get_keyboard_binding(selected_command)
  local old_joypad_binding = controls_ob:get_joypad_binding(selected_command)

  --Make sure we're not on the wrong screen to bind
  if control_type ~= menu.command_set then
    sol.audio.play_sound"wrong"
    menu.command_set = control_type
    menu:update_commands()
    input_capture_warning:invalid_control_type()
    show_invalid_input()
    menu:update_type_selector()
    return
  end
  --Check that command can be rebound
  if forbidden_commands[selected_command] then
    input_capture_warning:invalid_command()
    show_invalid_input()
    return
  end
  --Check that input is valid
  if forbidden_inputs[input] then
    sol.audio.play_sound"wrong"
    input_capture_warning:invalid_input()
    show_invalid_input()
    return
  end

  --Valid, bind new input
  assert((control_type == "joypad") or (control_type == "joypad_axis") or (control_type == "keyboard"), "Control binding error, invalid control_type given. Control type was: " .. control_type)
  menu:update_controls_with_new_binding(control_type, input, selected_command)

  --Validate that binding worked:
  --Removing this, with new controls manager, this is more dependable and is, hopefully, uneeded
  --[[
  if not validate_command_bound(controls_ob, selected_command) then
    --Roll back
    print("Some issue happened when binding, it didn't work. Control type:", control_type, "Input:", input, "Selected Command:", selected_command, "Old binding:", old_keyboard_binding, old_joypad_binding)
    sol.audio.play_sound"wrong"
    controls_ob:set_keyboard_binding(selected_command, old_keyboard_binding)
    controls_ob:set_joypad_binding(selected_command, old_joypad_binding)
  end
  --]]
  
end



function menu:on_draw(dst)
  menu.background:draw(dst)
  menu.window_surface:draw(dst, 416/2 - (command_area_size.width / 2) , 32)
  menu.type_selector_border:draw(dst, 416/2 - (panel_size.width / 2), 16)
end


function menu:on_started()
  menu.cursor_index = 1
  menu.active_input_capture = false
  menu:update_type_selector()
  menu:update_commands()
  menu:update_working_surface()
end


return menu
