local multi_events = sol.modules.get_object("multi_events")
local language_manager = sol.modules.get_object("language_manager")

local factory = {}

function factory.new(props)
  local menu = {}
  multi_events:enable(menu)

  menu.options = props.options or {}
  local draw_x, draw_y = props.x or 0, props.y or 0
  local cursor_style = props.cursor_style or "menus/arrow"
  local cursor_offset = props.cursor_offset or {x = 0, y = 0}
  local cursor_sound = props.cursor_sound or "cursor"
  local selection_sound = props.selection_sound or "ok"
  local width, height = props.width, props.height
  local background_color = props.background_color or {0,0,0,0}

  --Create surfaces
  local choice_surface = sol.surface.create()
  if width or height then
    choice_surface = sol.surface.create(width, height)
  end
  menu.choice_surfaces = {}

  local function draw_choices()
    choice_surface:clear()
    choice_surface:fill_color(background_color)

    local font, font_size = language_manager:get_menu_font()
    --Create and draw text surfaces
    for i, choice in ipairs(menu.options) do
      local pad_x, pad_y = 8, 4
      local txt = menu.choice_surfaces[choice] or sol.text_surface.create{
        font = font or "enter_command",
        font_size = font_size or 16,
      }
      local txt_key = sol.language.get_string("menu.title_screen." .. menu.options[i])
      if not txt_key then txt_key = sol.language.get_string("menu.options." .. menu.options[i]) end --check menu.options.choice if not found in menu.title_screen.choice
      txt:set_text(txt_key)
      txt:draw(choice_surface, pad_x, pad_y + 16 * (i - 1))
      menu.choice_surfaces[choice] = txt
    end
  end
  draw_choices()

  --Create cursor
  local cursor = sol.sprite.create(cursor_style)
  local cursor_index = 1

  function menu:get_cursor_index()
    return cursor_index
  end

  function menu:set_cursor_index(new_index)
    if new_index > #menu.options then
      new_index = 1
    elseif new_index <= 0 then
      new_index = #menu.options
    end
    cursor_index = new_index
  end


  menu:register_event("on_draw", function(self, dst)
    choice_surface:draw(dst, draw_x, draw_y)
    cursor:draw(dst, draw_x + cursor_offset.x, draw_y + 4 + 16 * (cursor_index - 1) + cursor_offset.y)
  end)


  function menu:move_cursor(command)
    sol.audio.play_sound(cursor_sound)
    local new_index
    if command == "up" then
      new_index = cursor_index - 1
    elseif command == "down" then
      new_index = cursor_index + 1
    end
    if new_index > #menu.options then
      new_index = 1
    elseif new_index <= 0 then
      new_index = #menu.options
    end
    cursor_index = new_index
  end


  function menu:switch_to_menu(new_menu)
    local top_menu = menu.top_menu
    sol.menu.start(top_menu, new_menu)
    top_menu:set_current_submenu(new_menu)
    sol.menu.stop(menu)
  end


  function menu:set_option_color(option, color)
    menu.choice_surfaces[option]:set_color_modulation(color)
    draw_choices()
  end


  function menu:update()
    draw_choices()
  end


  menu:register_event("process_input", function(self, command)
    local handled = false
    if command == "up" or (command == "down") then
      menu:move_cursor(command)
      handled = true
    elseif (command == "confirm") then
      sol.audio.play_sound(selection_sound)
      menu:process_selection(menu.options[cursor_index])
      handled = true

    elseif command == "cancel" then
      menu:process_selection("back")

    end
    return handled
  end)


  return menu

end

return factory
