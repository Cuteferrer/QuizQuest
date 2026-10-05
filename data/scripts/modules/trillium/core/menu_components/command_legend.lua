--[[
Created by Max Mraz, licensed MIT

Creates a menu that will show a command and its associated action. For example: [A] Confirm   [B] Exit
Usage:
local command_legend = sol.modules.get_object("trilmenu_component_command_legend").new(config)
sol.menu.start(parent_menu, command_legend)

Config Object:
example = {
  commands = {
    { command = "confirm",  action = "menu.actions.equip"},
    { command = "cancel",  action = "menu.actions.exit"},
  },
  x = 100, y = 100,
  orientation = "vertical"
}

commands: A table of key/value pairs. Key: Command, Value: String Key for what action will happen if you press that button
x, y: where to draw the menu
orientation: "horizontal" (default) or "vertical", sets whether the commands in the legend will be in a row, or stacked
--]]

local font, font_size = sol.modules.get_object("language_manager").get_menu_font()
local controls_manager = sol.controls.get_controls_manager()


local factory = {}

function factory.new(config)
  assert(config.commands, "You gotta pass commands in config.commands when you want a command legend from command_legend_factory.new(config). Get serious.")
  local commands_list = config.commands
  local origin_x, origin_y = config.x or 0, config.y or 0
  local orientation = config.orientation or "horizontal"

  local menu = {}

  menu.draw_surface = sol.surface.create()

  function menu:set_commands(commands)
    menu.command_boxes = {}
    for i = 1, #commands do
      menu.command_boxes[i] = menu:create_command_box(commands[i])
    end
    menu:draw_command_boxes()
  end

  function menu:create_command_box(command_conf)
    local command, action = command_conf.command, command_conf.action
    local sprite_id, animation = controls_manager:get_command_sprite_id(command)
    local sprite = sol.sprite.create(sprite_id)
    sprite:set_animation(animation)
    local text_surface = sol.text_surface.create{
      font = font, font_size = font_size,
      vertical_alignment = "bottom",
      text_key = action,
    }
    local sw, sh = sprite:get_size()
    local tw, th = text_surface:get_size()
    local width = (sw + tw + 16)
    local height = math.max(sh, th + 3)
    local cmd_surface = sol.surface.create(width, height)
    sprite:draw(cmd_surface, sw / 2, height - 3)
    text_surface:draw(cmd_surface, sw + 8, height - 1)
    return cmd_surface
  end

  function menu:draw_command_boxes()
    menu.draw_surface:clear()
    local current_offset = 0
    for i, box in ipairs(menu.command_boxes) do
      if orientation == "horizontal" then
        box:draw(menu.draw_surface, current_offset, 0)
        local bw, bh = box:get_size()
        current_offset = current_offset + bw + 8
      else
        box:draw(menu.draw_surface, 0, current_offset)
        local bw, bh = box:get_size()
        current_offset = current_offset + bh + 8
      end
    end
  end

  function menu:on_started()
    menu:set_commands(commands_list)
  end


  function menu:on_draw(dst)
    menu.draw_surface:draw(dst, origin_x, origin_y)
  end

  function menu:notify() end --stub to allow use as an aux menu with trillium menu system


  return menu

end


return factory
