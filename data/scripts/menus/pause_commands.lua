local commands_manager = {}

local gui_designer = require("scripts/menus/lib/gui_designer")
local commands_items = require("scripts/commands_config.lua")

function commands_manager:new(game)

  local commands_menu = {}

  local layout

  local cursor_index = 1
  local first_shown = 1
  local max_by_page = 8
  game.customizing_command = false
  local customizing_timer
  local customizing_background_displayed = true

  -- Remove elements not known yet.
  for i = #commands_items, 1, -1 do
    local item = commands_items[i]
    if not item.unlocked then
      table.remove(commands_items, i)
    end
  end

  local function build_layout()

    layout = gui_designer:create(320, 240)

    layout:make_wooden_frame(16, 8, 96, 32)
    local title = sol.language.get_string("pause.commands.title")
    layout:make_text(title, 64, 16, "center")

    layout:make_wooden_frame(128, 8, 80, 32)
    local title = sol.language.get_string("pause.commands.keyboard")
    layout:make_text(title, 168, 16, "center")

    layout:make_wooden_frame(224, 8, 80, 32)
    local title = sol.language.get_string("pause.commands.joypad")
    layout:make_text(title, 264, 16, "center")

    layout:make_wooden_frame(16, 200, 288, 32)
    if commands_items[cursor_index].customizable then
      local footer = game.customizing_command and
          sol.language.get_string("pause.commands.press_new_key") or
          sol.language.get_string("pause.commands.action_to_configure")
      layout:make_text(footer, 24, 208)
    end

    layout:make_wooden_frame(16, 48, 288, 144)

    local first = first_shown
    local last = math.min(#commands_items, first_shown + max_by_page - 1)
    local y = 56
    for i = first, last do
      local item = commands_items[i]
      if item == nil then
        break
      end

      if cursor_index == i then
        local color
        if game.customizing_command then
          if customizing_background_displayed then
            color = { 255, 0, 0 }
          end
        else
          color = { 0, 0, 192 }
        end
        if color ~= nil then
          layout:make_color_background(color, 24, y, 272, 16)
        end
      end

      local name = sol.language.get_string("pause.commands." .. item.name)
      assert(name ~= nil)
      layout:make_text(name, 24, y)

      local keyboard_text
      local joypad_text
      if item.customizable then
        keyboard_text = game:get_custom_command_keyboard_binding(item):gsub("^%l", string.upper)
        joypad_text = game:get_custom_command_joypad_binding(item):gsub("^%l", string.upper)
      else
        -- Non-customizable command from the quest.
        keyboard_text = item.default_key
      end

      layout:make_text(keyboard_text, 136, y)
      if joypad_text ~= nil then
        layout:make_text(joypad_text, 232, y)
      end

      y = y + 16
    end
  end

  local function stop_customizing()

    sol.audio.play_sound("danger")
    game.customizing_command = false
    customizing_timer:stop()
    build_layout()
  end

  function commands_menu:on_command_pressed(command)

    local handled = false

    if command == "up" then
      if cursor_index == 1 then
        cursor_index = #commands_items
        first_shown = math.max(1, #commands_items - max_by_page + 1)
      else
        if cursor_index == first_shown then
          first_shown = first_shown - 1
        end
        cursor_index = cursor_index - 1
      end
      sol.audio.play_sound("cursor")
      build_layout()
      handled = true

    elseif command == "down" then
      if cursor_index == #commands_items then
        cursor_index = 1
        first_shown = 1
      else
        local last_shown = math.min(#commands_items, first_shown + max_by_page - 1)
        if cursor_index == last_shown then
          first_shown = first_shown + 1
        end
        cursor_index = cursor_index + 1
      end
      sol.audio.play_sound("cursor")
      build_layout()
      handled = true

    elseif command == "action" then
      if not game.customizing_command and commands_items[cursor_index].customizable then  -- Customizing a game command.
        sol.audio.play_sound("ok")
        game.customizing_command = true
        customizing_timer = sol.timer.start(commands_menu, 300, function()
          -- Make the red row blink.
          customizing_background_displayed = not customizing_background_displayed
          build_layout()
          return true
        end)
        build_layout()
        handled = true
      end

    end

    return handled
  end

  function commands_menu:on_key_pressed(key)

    if not game.customizing_command then
      return false
    end

    local item = commands_items[cursor_index]
    game:set_custom_command_keyboard_binding(item, key)
    stop_customizing()
    return true
  end

  function commands_menu:on_joypad_button_pressed(button)

    if not game.customizing_command then
      return false
    end

    local item = commands_items[cursor_index]
    local command = item.command
    local joypad_action = "button " .. button
    game:set_custom_command_joypad_binding(item, joypad_action)
    stop_customizing()
    return true
  end

  function commands_menu:on_joypad_axis_moved(axis, state)

    if not game.customizing_command then
      return false
    end

    if state == 0 then
      return false
    end

    local item = commands_items[cursor_index]

    if item.command == nil then
      -- For additional commands from the quest, joypad axis are not supported yet.
      return false
    end

    local joypad_action = "axis " .. axis .. " " .. (state > 0 and "+" or "-")
    game:set_custom_command_joypad_binding(item, joypad_action)
    stop_customizing()
    return true
  end

  function commands_menu:on_joypad_hat_moved(hat, direction8)

    if not game.customizing_command then
      return false
    end

    if direction8 == -1 then
      return false
    end

    local item = commands_items[cursor_index]

    if item.command == nil then
      -- For additional commands from the quest, joypad hats are not supported yet.
      return false
    end

    local joypad_action = "hat " .. hat .. " " .. direction8
    game:set_custom_command_joypad_binding(item, joypad_action)
    stop_customizing()
    return true
  end

  function commands_menu:on_draw(dst_surface)

    layout:draw(dst_surface)
  end

  build_layout()

  return commands_menu
end

return commands_manager
