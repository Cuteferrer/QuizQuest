--[[
Created by Max Mraz, licensed MIT
Shows current control bindings (has no functionality to change them)
--]]

local font, font_size, line_height = sol.modules.get_object("language_manager"):get_menu_font()

local menu = { x = 32, y = 16, }
menu.width, menu.height = 352, 208
menu.input_type = "keyboard"

local menu_surface = sol.surface.create()
local bg_surface = sol.modules.get_object("trilmenu_nineslice").get_surface{
  width = menu.width, height = menu.height,
  source_png = "menus/panel_blocks/small.png",
  tile_width = 8, tile_height = 8,
}
local input_diagrams = {
  ["xbox"] = sol.surface.create("menus/controls/input_type_diagram_xbox.png"),
  ["playstation"] = sol.surface.create("menus/controls/input_type_diagram_playstation.png"),
  ["switch"] = sol.surface.create("menus/controls/input_type_diagram_switch.png"),
  ["generic"] = sol.surface.create("menus/controls/input_type_diagram_xbox.png"),
  ["keyboard"] = sol.surface.create("menus/controls/input_type_diagram_keyboard.png"),
}


local commands = {
  "movement", --handle special
  "action",
  "pause",
  "dodge",
  "attack",
  "aim",
  "fire",
  "item_1",
  "item_2",
  "quickswaps", --handle special
  "weapon_art",
  "wraithshot",
  "hookshot"
}



function menu:create_controls_surface()
  local width, height = 224, 232
  local num_rows = 6
  local row_height, column_width = 32, 80
  local controls_surface = sol.surface.create(width, height)

  local controls_ob = sol.controls.get_main_controls()
  local controls_manager = sol.controls.get_controls_manager()
  local sprite_type = menu.input_type
  local button_sprite = sol.sprite.create("hud/button_icons/" .. sprite_type)

  --local bindings = active_input_type == "keyboard" and controls_ob:get_keyboard_bindings() or controls_ob:get_joypad_bindings()
  local row_index = 0
  local column_index = 0
  for _, command in ipairs(commands) do
    local txt = sol.text_surface.create{font = font, font_size = font_size, horizontal_alignment = "left", vertical_alignment = "top",}
    local icon_surface

    if command == "movement" or command == "quickswaps" then
      local bundled_commands = {}
      icon_surface = sol.surface.create(column_width, row_height)
      if command == "movement" then
        txt:set_text_key("options.command.movement_stick")
        bundled_commands = {"up", "left", "down", "right"}
      elseif command == "quickswaps" then
        txt:set_text_key("options.command.quickswap")
        bundled_commands = {"quickswap_melee", "quickswap_gun", "quickswap_item_1", "quickswap_item_2"}
      end
      for i, cmd in ipairs(bundled_commands) do
        local sprite_id, animation = controls_manager:get_command_sprite_id(cmd)
        button_sprite:set_animation(animation)
        button_sprite:draw(icon_surface, i * 16 - 8, 13)
      end
      icon_surface:draw(controls_surface, column_index * column_width, row_index * row_height + 16)

    else
      txt:set_text_key("options.command." .. command)
      local sprite_id, animation = controls_manager:get_command_sprite_id(command)
      button_sprite:set_animation(animation)
      icon_surface = button_sprite
      icon_surface:draw(controls_surface, column_index * column_width + 12, row_index * row_height + 16 + 10)
    end
    txt:draw(controls_surface, column_index * column_width, row_index * row_height)
    row_index = row_index + 1
    if row_index > (num_rows - 1) then
      row_index = 0
      column_index = column_index + 1
    end
  end

  return controls_surface
end



function menu:create_mouse_surface()
  local width, height = 112, 128
  local cmd_y_offset = 32
  local row_height = 32
  local controls_surface = sol.surface.create(width, height)
  local mouse_diagram = sol.surface.create("menus/controls/input_type_diagram_mouse.png")
  --left = aaim, right = fire, other = attack
  local mouse_bindings = {
    {"mouse_left", "attack"},
    {"mouse_right", "aim"},
    {"mouse_special", "special"},
  }
  mouse_diagram:draw(controls_surface, 0, 0)
  for i, binding in ipairs(mouse_bindings) do
    local animation, command = binding[1], binding[2]
    local txt = sol.text_surface.create{
      font = font, font_size = font_size,
      horizontal_alignment = "left", vertical_alignment = "top",
      text_key = "options.command." .. command,
    }
    local mouse_sprite = sol.sprite.create("hud/button_icons/keyboard")
    mouse_sprite:set_animation(animation)
    txt:draw(controls_surface, 8, (i-1) * row_height + cmd_y_offset)
    mouse_sprite:draw(controls_surface, 8 + 8, (i-1) * row_height + 13 + cmd_y_offset + line_height)
  end
  return controls_surface
end



function menu:set_input_type()
  local controls_ob = sol.controls.get_main_controls()
  local controls_manager = sol.controls.get_controls_manager()
  local active_input_type = controls_manager.get_active_input_type()
  local joypad_type = controls_manager.get_joypad_type()
  menu.input_type = active_input_type == "keyboard" and "keyboard" or joypad_type
end



function menu:on_started()
  menu:set_input_type()
  menu.input_diagram = input_diagrams[menu.input_type]
  menu.controls_surface = menu:create_controls_surface()
  menu.mouse_addendum = menu:create_mouse_surface()
end



function menu:on_draw(dst)
  bg_surface:draw(dst, menu.x, menu.y)
  menu.input_diagram:draw(dst, menu.x + 16, menu.y + 16)
  menu.controls_surface:draw(dst, 144, 24)
  if menu.input_type == "keyboard" then
    menu.mouse_addendum:draw(dst, 48, 72)
  end
end


function menu:on_command_pressed(command)
  if command == "cancel" or command == "pause" then
    sol.menu.stop(menu)
  end
  return true
end


return menu
