--[[
Created by Max Mraz, licensed MIT
Adapter to interface with whatever button/command binding system is in place.
This manager must contain a function called manager:get_command_sprite_id(command)
The dialog will call manager:get_command_sprite_id(command), which much return a string of dialog sprite information to the dialog system
The sprite information string can be formatted (without animation) like: "path/to/sprite" -OR- (with animation) "path/to/sprite?animation=some_animation"

This implementation is designed to work with the controls_manager script I've written
--]]

local manager = {}
local controls_manager = sol.controls.get_controls_manager()

function manager:get_command_sprite_id(command)
  --Define this function such that it returns a sprite id (string)(with optional animation argument) based on the command string passed as an argument

  --Command translations. Use to allow special commands in dialogs that aren't necessarily tied to a game command
  local command_translation_lookup = {
    ["joypad"] = {
    },
    ["keyboard"] = {
    },
    ["keyboard_and_mouse"] = {
    },
  }

  local game = sol.main.get_game()
  local controls_ob = sol.controls.get_main_controls()
  local sprite_id
  local command_display_pref = game:get_value("option_display_controls_as") or "keyboard"
  local command_display_style = controls_ob.joypad and "joypad" or command_display_pref

  --Check command translation to map special commands to general ones:
  local translated_command = command_translation_lookup[command_display_style][command]
  if translated_command then command = translated_command end
  if command_display_style == "joypad" then
    local button_name = controls_ob:get_joypad_binding(command):gsub(" %+", ""):gsub(" %-", "")
    local joypad_type = controls_manager.get_joypad_type() or "generic"
    sprite_id = "hud/button_icons/" .. joypad_type .. "?animation=" .. button_name

  elseif command_display_style == "keyboard" then
    local key = controls_ob:get_keyboard_binding(command):gsub(" ", "_")
    sprite_id = "hud/button_icons/keyboard?animation=" .. key

  else --default to keyboard/mouse display:
    --Note: same as keyboard display since there are no mouse-unique buttons
    --Showing both mouse and keyboard is handled by also calling :get_command_spite_id_mouse() for the command
    --and drawing both returned sprites
    local key = controls_ob:get_keyboard_binding(command):gsub(" ", "_")
    sprite_id = "hud/button_icons/keyboard?animation=" .. key

  end

  return sprite_id
end


function manager:get_command_sprite_id_mouse(command)
  --Don't show any if you're using joypad controls:
  local controls_ob = sol.controls.get_main_controls()
  if (controls_ob.joypad) then
    return nil
  end

  local mappings = {
    ["attack"] = "mouse_left",
    ["fire"] = "mouse_left",
    ["aim"] = "mouse_right",
    ["wraithshot"] = "mouse_special",
    ["hookshot"] = "mouse_special",
  }
  local key = mappings[command]
  if key then
    return "hud/button_icons/keyboard?animation=" .. key
  else
    return nil --no mouse sprite found
  end

end


return manager
