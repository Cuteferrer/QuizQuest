local bg_9slicer = sol.modules.get_object("trilmenu_nineslice")
local language_manager = sol.modules.get_object("language_manager")
local config_manager = require("scripts/modules/trillium/dialog/libs/config_manager")
local midline_options = require("scripts/modules/trillium/dialog/libs/midline_option_manager")
local profile_manager = require("scripts/modules/trillium/dialog/libs/profile_manager")

local menu = {}

sol.modules.get_object("multi_events"):enable(menu)

local font, font_size, vert_spacing = language_manager:get_dialog_font()

local config = config_manager:get_default_config()


function menu:get_config()
  return config
end

function menu:set_config(new_config)
  config = new_config
end


local function get_bg()
  if config.bg_type == "9slice" then
    return bg_9slicer.get_surface{
      width = config.width, height = config.height,
      source_png = config.bg_source,
      tile_width = config.slice_width, tile_height = config.slice_height,
    }
  else
    return sol.surface.create(config.bg_source)
  end
end

local function get_line_surfaces()
  local line_surfaces = {}
  for i = 1, config.visible_lines do
    line_surfaces[i] = sol.text_surface.create{
      font = font,
      font_size = font_size,
      vertical_alignment = "top",
    }
  end
  return line_surfaces
end



function menu:on_started()
  --TODO: allow menu.info to override visible_lines config (note: should we set menu height dynamically too then?)

  --Reset font in case language has changed:
  font, font_size, vert_spacing = language_manager:get_dialog_font()

  --Set/Reset config
  menu:set_config(config_manager:get_default_config())
  if menu.info.config_override_file then
    config_manager:load_config(menu, menu.info.config_override_file)
  end

  --Create surfaces:
  menu.bg_surface = get_bg()
  menu.draw_surface = sol.surface.create(config.width, config.height)
  menu.text_surface = sol.surface.create(config.width, config.height)
  menu.line_surfaces = get_line_surfaces()
  menu.sprite_surface = sol.surface.create(config.width, config.height)
  menu.cursor_surface = sol.surface.create(config.width, config.height)
  menu.cursor = sol.sprite.create(config.cursor_sprite)
  menu.cursor:set_opacity(0)
  menu.portrait_surface = sol.surface.create()
  menu.current_profile = nil

  --Initialize variables
  menu.surface_index = 0
  menu.line_index = 0
  menu.question_active = false
  menu.cursor_index = 1
  menu.vox_blip_cooldown = false

  profile_manager:set_config(config)
  menu:opening_animation()

  menu:show_dialog()
end

function menu:on_finished()

end


--Exit dialog:
function menu:quit()
  sol.menu.stop(menu)
  local game = sol.main.get_game()
  if game then
    game:on_dialog_finished(menu.dialog)
  end
  --Stop dialog (activating callback)
  local arg
  if menu.question_active then arg = menu.cursor_index end
  game:stop_dialog(arg)

  --Clean up dialog variables
  menu.dialog = nil
  menu.info = nil

  profile_manager:unset_profile()
end


--Break a string into an array of lines
local function create_lines(text)
  local lines = {}
  for s in text:gmatch("([^\n]*)\n") do --break out each line, including empty lines
      table.insert(lines, s)
  end
  return lines
end


function menu:get_surface_y_position(surface_index)
  return config.text_offset.y + surface_index * vert_spacing
end


local function check_if_line_is_choice(line_index, surface_index)
  --Activates the question state, the cursor, and sets the surface index for the choice so we know where to draw it
  if menu.choice_lines[line_index] then
    --Activate question state:
    menu.question_active = true
    --Set display_line on choice so we know where to draw the cursor:
    local choice_number = menu.choice_lines[line_index].choice_number
    menu.choice_lines[line_index].display_line = surface_index
    menu.choices[choice_number].display_line = surface_index
    --Activate cursor
    menu.cursor:set_opacity(255)
    menu:draw_cursor()
  end
end


local function is_last_line()
  local line_index = menu.line_index
  local is_last = false

  --Check if last line on surface
  if menu.surface_index >= config.visible_lines then
    is_last = true
  --Check last line in dialog:
  elseif not menu.lines[line_index + 1] then
    is_last = true
  --Check for page breaks on next line
  elseif menu.lines[line_index + 1] and menu.lines[line_index + 1]:match("^%$pb") then
    is_last = true
  --If this is a choice and there's not another choice next
  elseif menu.choice_lines[line_index] and not menu.choice_lines[line_index + 1] then
    is_last = true
  elseif menu.lines[line_index + 1]:match("^@") then
    is_last = true
  end

  return is_last
end


local function should_skip_drawing_line(line)
  --Don't draw a line under certain circumstances. For example: comments, page breaks, etc.
  local should_skip
  if line:match("^%$pb") then
    --If line is a page break
    should_skip = true
  elseif line:match("^//") then
    --Line is a comment
    should_skip = true
  elseif line:match("^@") then
    --Line is a name/profile
    profile_manager:set_profile(line:gsub("@", ""), menu)
    should_skip = true
  end
  return should_skip
end


local function draw_line(line_index, surface_index)
  --Check if line is a choice, offset if so:
  local choice_offset = 0
  if menu.choice_lines[line_index] then
    choice_offset = config.choice_offset
  end

  local surface = menu.line_surfaces[surface_index]
  --This only draws the portion that hasn't yet been drawn
  local width, height = surface:get_size()
  --Offset the position so we don't draw over a previously drawn character
  surface.write_position_offset = surface.write_position_offset or 0

  --Draw
  surface:draw_region(
    surface.write_position_offset,
    0,
    width,
    height,
    menu.text_surface,
    config.text_offset.x + choice_offset + surface.write_position_offset,
    menu:get_surface_y_position(menu.surface_index)
  )
  surface.write_position_offset = width
end




function menu:show_dialog()
  local dialog = menu.dialog
  local text = menu.dialog.text
  local info = menu.info

  --Substitute variables from info
  text = midline_options:variable_sub(text, info)

  --Turn into array of lines
  menu.lines = create_lines(text)

  --Check for names, choices, comments, etc.
  midline_options:process_lines(menu)

  menu:show_next_dialog_screen()
end


function menu:show_next_dialog_screen()
  --Check if there are more lines to show:
  if #menu.lines > menu.line_index then
    --Set typing flag to prevent skipping to next screen while current is typing
    menu.currently_typing = true
    menu.surface_index = 0
    --Clear surfaces
    menu.text_surface:clear()
    menu.sprite_surface:clear()

    menu:show_next_line()
  else
    menu:quit()
  end
end


function menu:show_next_line()
  local line_index = menu.line_index + 1
  local surface_index = menu.surface_index + 1
  local line = menu.lines[line_index]
  menu.current_character_index = 0

  --Reset line variables
  local surface = menu.line_surfaces[surface_index]
  surface:set_text("")
  surface.write_position_offset = 0
  surface:set_color_modulation(config.default_font_color)

  if line == nil then
    --No more lines in whole dialog
    menu.currently_typing = false
  elseif should_skip_drawing_line(line) then
    --Skip drawing line:
    menu.line_index = line_index
    menu:show_next_line()
  else
    --Start drawing line:
    check_if_line_is_choice(line_index, surface_index)
    menu:show_next_character(line_index, surface_index)
  end

end


function menu:show_next_character(line_index, surface_index)
  --Re-calls itself until all characters in the line are shown; once all are, calls menu:show_next_line()
  local char_index = menu.current_character_index + 1
  local line = menu.lines[line_index]
  --If we've reached the end of the whole dialog, stop:
  if line == nil then
    menu.currently_typing = false
    return
  end

  --Check for special midline option characters
  line = midline_options:check_midline(menu, line, char_index)
  --Update line index if there were any changes:
  menu.lines[line_index] = line

  --[[Get current substring, set and draw it
  local line_segment = line:sub(1, char_index)
  menu.line_surfaces[surface_index]:set_text(line_segment)
  draw_line(line_index, surface_index)
  --]]
  --Get next character, add it, and draw it
  local next_char = line:sub(char_index, char_index)
  local surface = menu.line_surfaces[surface_index]
  surface:set_text(surface:get_text() .. next_char)
  draw_line(line_index, surface_index)

  --Play vox blip sound
  menu:play_vox_blip(next_char)

  menu.current_character_index = char_index

  if menu.current_character_index <= line:len() then --Next character
    local delay = config.character_delay
    --No delay if we're showing the whole dialog at once:
    if menu.dialog_skip_fast_forward then delay = 0 end
    sol.timer.start(menu, delay, function()
      --Continue onto the next character:
      menu:show_next_character(line_index, surface_index)
    end)

  else
    --No more characters in this line. Increment and check if we need to show more
    menu.line_index = line_index
    menu.surface_index = surface_index
    if not is_last_line() then
      menu:show_next_line()
    else
      --No more lines in this dialog screen
      --Finish typing flag
      menu.currently_typing = false
      menu.dialog_skip_fast_forward = false
    end    
  end
end


function menu:finish_typing_now()
  menu.dialog_skip_fast_forward = true
end



function menu:draw_cursor()
  local choice = menu.choices[menu.cursor_index]
  menu.cursor_surface:clear()
  menu.cursor:draw(
    menu.cursor_surface,
    config.cursor_offset.x,
    config.cursor_offset.y + (choice.display_line * vert_spacing )
  )
end

function menu:move_cursor(direction)
  sol.audio.play_sound(config.cursor_sound)
  menu.cursor_index = menu.cursor_index + (1 * direction)
  if menu.cursor_index > #menu.choices then menu.cursor_index = 1
  elseif menu.cursor_index <= 0 then menu.cursor_index = #menu.choices end
  menu:draw_cursor()
end


--Sounds
function menu:play_vox_blip(char)
  char = char or "a"
  --convert char to number:
  char = char:byte()
  if not menu.vox_blip_cooldown then
    --Choose blip
    local blip_se
    if menu.active_profile and menu.active_profile.vox_blips then
      blip_se = menu.active_profile.vox_blips[(char or 1) % (#menu.active_profile.vox_blips) + 1]
    else
      blip_se = config.vox_blips[(char or 1) % (#config.vox_blips) + 1]
    end
    sol.audio.play_sound(blip_se)

    menu.vox_blip_cooldown = true
    local cooldown_time = config.vox_blip_frequency
    if menu.active_profile and menu.active_profile.vox_blips_frequency then
      cooldown_time = menu.active_profile.vox_blips_frequency
    end
    sol.timer.start(menu, cooldown_time, function()
      menu.vox_blip_cooldown = false
    end)
  end
end


--Profile / Portrait
function menu:set_portrait(profile)
  menu.portrait_surface:clear()
  if not profile.portrait then return end
  local portrait = sol.surface.create(profile.portrait.path)
  if menu.current_profile ~= profile then
    menu.current_profile = profile
    menu.portrait_surface:fade_in(1)
  end
  local screen_width, screen_height = sol.video.get_quest_size()
  local width, height = portrait:get_size()
  local offset_x = 0
  if profile.portrait.position == "right" then
    offset_x = screen_width - width
  end
  portrait:draw(menu.portrait_surface, offset_x + profile.portrait.offset_x, profile.portrait.offset_y)
end


function menu:on_command_pressed(command)
  local handled = false
  if command == "confirm" then
    --Finish this dialog screen:
    if menu.currently_typing then
      menu:finish_typing_now()
    --Confirm choice selection:
    elseif menu.question_active then
      --We'll pass back the choice from menu.cursor_index, but you can continue further dialog if desired
      menu.cursor:set_opacity(0)
      menu:draw_cursor()
      menu:show_next_dialog_screen()
    --Next dialog screen, or else close if there is none:
    else
      menu:show_next_dialog_screen()
    end
    local handled = true
    return handled --I've no idea why, but this needs to return here and now, after the "if" block won't do

  elseif command == "cancel" or command == "attack" then
    --Finish this dialog screen:
    if menu.currently_typing then
      menu:finish_typing_now()
    end
    handled = true

  elseif (command == "up") then
    if menu.question_active then
      menu:move_cursor(-1)
    end
    handled = true
  elseif (command == "down") then
    if menu.question_active then
      menu:move_cursor(1)
    end
    handled = true
  elseif command == "right" or command == "left" then
    handled = true

  end

  return true --we never want button commands to go to the game while a dialog is open
end

function menu:opening_animation()
  local slide_offset = 64
  local angle = math.pi / 2
  menu.draw_surface:fade_in(5)
  local dx = math.floor(math.cos(angle) * slide_offset) * -1
  local dy = math.floor(math.sin(angle) * slide_offset)
  menu.draw_surface:set_xy(dx, dy)
  local m = sol.movement.create("straight")
  m:set_speed(480)
  m:set_max_distance(slide_offset)
  m:set_angle(angle)
  m:start(menu.draw_surface)
end


function menu:update_draw_surface()
  --[[
  menu.bg_surface:draw(menu.draw_surface, config.origin_x, config.origin_y)
  menu.sprite_surface:draw(menu.draw_surface, config.origin_x + config.text_offset.x, config.origin_y)
  menu.text_surface:draw(menu.draw_surface, config.origin_x, config.origin_y)
  menu.cursor_surface:draw(menu.draw_surface, config.origin_x, config.origin_y)
  --]]
  menu.bg_surface:draw(menu.draw_surface, 0, 0)
  menu.sprite_surface:draw(menu.draw_surface, config.text_offset.x, 0)
  menu.text_surface:draw(menu.draw_surface, 0, 0)
  menu.cursor_surface:draw(menu.draw_surface, 0, 0)
end


function menu:on_draw(dst)
  menu.portrait_surface:draw(dst)
  menu:update_draw_surface()
  menu.draw_surface:draw(dst, config.origin_x, config.origin_y)
end


return menu
