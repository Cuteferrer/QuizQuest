--[[
Written by Max Mraz, licensed MIT

In game:start_dialog(id, info, callback), info must be a table, if it is included

Putting variables in your dialog:
In a dialog, you can sub in variables with $v1, $v2, $v16, etc. The info table must have corresponding values like
    local info = {
    v1 = game:get_value("fishing_minigame_score"),
    v2 = sol.language.get_string("island_inn_name"),
    etc
    }


--]]

local command_adapter = require("scripts/modules/trillium/dialog/libs/command_adapter")

local manager = {}


function manager:process_lines(menu)
  --Check for and remove comments
  --Dialog comments (like translation notes) should start with //
  manager:remove_comments(menu)

  --Check for choices
  manager:setup_choices(menu)
end


function manager:variable_sub(text, info)
  for k, v in pairs(info) do
    if k:match("v%d+") then
      text = text:gsub("%$" .. k, v)
    end
  end

  return text
end


function manager:remove_comments(menu)
  for i, line in ipairs(menu.lines) do
    line = line:gsub("//.*", "")
    menu.lines[i] = line
  end
end


function manager:setup_choices(menu)
  --[[
    Sets up menu.choices and menu.choice_lines
    Choices can be checked by menu.choices[choice_number](relative to number of choices) or menu.choice_lines[line_number](relative to whole text]
  --]]
  local choices = {}
  local choice_lines = {}
  local choice_number = 1
  for i, line in ipairs(menu.lines) do
    if line:match("%$%?") then
      menu.lines[i] = line:gsub("%$%?", "")
      choices[choice_number] = {
        choice_number = choice_number,
        line_number = i,
        display_line = 1, --will be set properly later
      }

      choice_lines[i] = choices[choice_number]
      choice_number = choice_number + 1
    end
  end
  menu.choices = choices
  menu.choice_lines = choice_lines
end


--Checks for special tags in the line, takes action if found, and returns the line with any changes
function manager:check_midline(menu, line, char_index)
  local char = line:sub(char_index, char_index)

  if char:match("%$") then
    local tag = line:match("%$[%w_=/%?]+%$", char_index)

    if not tag then
      return line
    end

    --Remove tag from menu line:
    line = line:gsub("%$[%w_=/%?]+%$", "", 1)

    --Strip $ characters from tags to read them more easily:
    tag = tag:gsub("%$", "")
    --Do stuff with tags
    if tag:match("^color") then
      local color_key = tag:gsub("color=", "")
      manager:set_color(menu, color_key)

    elseif tag:match("^font") then
      local font = tag:gsub("font=", "")
      manager:set_font(menu, font)

    elseif tag:match("^size") then
      local size = tag:gsub("size=", "")
      manager:set_size(menu, size)


    elseif tag:match("^sprite") then
      local sprite_id = tag:gsub("sprite=", "")
      local num_spaces, spaces = manager:draw_sprite(menu, sprite_id, char_index)
      --Insert spaces into the line to leave room for the sprite:
      line = line:sub(1, char_index - 1) .. spaces .. line:sub(char_index + 1)

    elseif tag:match("^command") then
      local command = tag:gsub("command=", "")
      local sprite_id = command_adapter:get_command_sprite_id(command)
      local mouse_sprite_id = command_adapter:get_command_sprite_id_mouse(command)
      --If there's a corresponding mouse sprite as well, draw both:
      local x_offset, mouse_spaces = 0, ""
      if mouse_sprite_id then
        _, mouse_spaces = manager:draw_sprite(menu, mouse_sprite_id, char_index)
        x_offset = 24
        --Insert spaces into the line to leave room for the sprite:
        line = line:sub(1, char_index - 1) .. mouse_spaces .. line:sub(char_index + 1)
      end
      local num_spaces, spaces = manager:draw_sprite(menu, sprite_id, char_index, x_offset)
      local moused_spaces = mouse_sprite_id and (mouse_spaces .. "/" ..spaces) or spaces
      --Insert spaces into the line to leave room for the sprite:
      line = line:sub(1, char_index - 1) .. moused_spaces .. line:sub(char_index + 1)

    elseif tag:match("^sound") then
      local sound = tag:gsub("sound=", "")
      sol.audio.play_sound(sound)

    end

    return line
  else --no $ chars to check
    return line
  end
end



function manager:set_color(menu, color_key)
  local color = {255,255,255}
  local preset_colors = {
    red = {200, 10, 0},
    green = {0, 200, 300},
    blue = {0, 110, 220},
    yellow = {255,210,0},
    orange = {255,100,0},
    purple = {190, 0, 100},
    grey = {100, 100, 100},
    gray = {100, 100, 100},
    white = {255, 255, 255},
    ivory = {255, 230, 170},
  }
  if type(color_key) == "table" then
    color = color_key
  elseif color_key == "default" then
    color = menu:get_config().default_font_color
  elseif preset_colors[color_key] then
    color = preset_colors[color_key]
  end

  menu.line_surfaces[menu.surface_index + 1]:set_color_modulation(color)
end


function manager:set_font(menu, font)
  menu.line_surfaces[menu.surface_index + 1]:set_font(font)
end


function manager:set_size(menu, size)
  menu.line_surfaces[menu.surface_index + 1]:set_font_size(size)
end


function manager:draw_sprite(menu, sprite_id, char_index, x_offset)
  x_offset = x_offset or 0
  local animation = sprite_id:match("%?animation=([%w_]+)")
  local direction = sprite_id:match("%?direction=(%d)")
  if animation then
    --Remove the animation tag
    sprite_id = sprite_id:gsub("%?animation=[%w_]+", "")
  end
  if direction then
    sprite_id = sprite_id:gsub("%?direction=%d", "")
  end

  local sprite = sol.sprite.create(sprite_id)
  if animation then sprite:set_animation(animation) end
  if direction then sprite:set_direction(direction) end
  --Measure current surface width to know where to draw sprite
  local sprite_w, sprite_h = sprite:get_size()
  local surface = menu.line_surfaces[menu.surface_index + 1] --menu.surface_index is only incremented when the line is _done_ writing, which is maybe a bit dumb. oops.
  local current_surface_width, height = surface:get_size()
  --Create a text surface to measure the width of a space, to automatically offset later characters in the line by the sprite width
  local font, font_size = surface:get_font(), surface:get_font_size()
  local space_width, line_height = sol.text_surface.create({font = font, font_size = font_size, text = "_",}):get_size()

  sprite:draw(
    menu.sprite_surface,
    current_surface_width + (sprite_w / 2) + x_offset,
    menu:get_surface_y_position(menu.surface_index) + line_height - 3
  )

  local num_spaces_needed = math.ceil(sprite_w / space_width) + 1
  local spaces = ""
  for i = 1, num_spaces_needed do
    spaces = spaces .. " "
  end
  return num_spaces_needed, spaces

end


return manager
