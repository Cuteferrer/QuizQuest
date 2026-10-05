-- Create menus that display their contents in a grid.
-- Note: you can put as many objects into the grid as you want, they only scroll vertically though

-- Licensed under MIT. Authored by Cluedrew, J. Cournoyer, and Max Mraz.

local multi_events = sol.modules.get_object("multi_events")
local default_settings = require("scripts/modules/trillium/core/menu_lib/default_settings")
local bg_9slice_manager = require("scripts/modules/trillium/core/menu_lib/nineslice_background_manager")
local menu_features_manager = require("scripts/modules/trillium/core/menu_lib/menu_features")

local grid_menu = {}

local menu_prototype = {}
multi_events:enable(menu_prototype)

local menu_metatable = {__index = menu_prototype}


function grid_menu.create(config)
    local menu = {}

    --Optional Paramters are handled first and include defaults
    --in case they are not defined in the config.
    menu.origin_x = config.origin and config.origin.x or 30
    menu.origin_y = config.origin and config.origin.y or 40
    menu.cell_width = config.cell_size and config.cell_size.width or 16
    menu.cell_height = config.cell_size and config.cell_size.height or 16
    menu.cell_spacing = config.cell_spacing or 2
    menu.edge_spacing = config.edge_spacing or 4
    menu.category_scroll_lock = config.category_scroll_lock or true
    menu.cursor_edge_behavior = config.cursor_edge_behavior or "loop"
    menu.cursor_style = config.cursor_style or default_settings.grid_cursor
    menu.cursor_sound = config.cursor_sound
    menu.cursor_offset_x = config.cursor_offset and config.cursor_offset.x or 0
    menu.cursor_offset_y = config.cursor_offset and config.cursor_offset.y or 0
    menu.scroll_arrow_style = config.scroll_arrow_style or default_settings.grid_scroll_arrow_style
    menu.background_color = config.background_color or {0,0,0,0}
    menu.background_png = config.background_png
    menu.background_9slice_config = config.background_9slice_config
    menu.background_offset = config.background_offset or {x=0, y=0}
    menu.cell_color = config.cell_color or {0,0,0,0}
    menu.cell_png = config.cell_png
    menu.fade_in_speed = config.fade_in_speed
    menu.aux_menus = config.aux_menus or {}

    --A title for the Menu might be a good idea in the future.
    --Could be helpful for debugging the menus; like in the assert
    --lines below. This would be a reason for handling these first, maybe.
    --menu.title = config.title_key or sol.language.get_string()

    --Mandatory Parameters are handled last. An error is thrown
    --if the specified parameter is not found.
    menu.total_columns = assert(config.grid_size.columns, "Menu is missing parameter for # of Columns")
    menu.visible_rows = assert(config.grid_size.rows, "Menu is missing parameter for # of Rows")
    menu.allowed_objects = assert(config.allowed_objects, "Menu is missing table of objects to be displayed.")

    --Derived Paramters are determined after all other parameters.
    menu.total_num_cells = #menu.allowed_objects
    menu.total_rows = math.ceil(menu.total_num_cells / menu.total_columns)
    --Note: further derived parameters are set in menu:update_objects(), as these are derived from each object's object.display_function()
    --These further parameters are menu.displayed_objects (table of objects that are currently active in the menu), menu.displayed_num_cells and menu.displayed_rows

    setmetatable(menu, menu_metatable)

    menu_features_manager.apply_menu_features(menu)
    menu_features_manager.apply_grid_menu_features(menu)

    return menu
end



--Define behaviour for the startup of every grid menu.
menu_prototype:register_event("on_started", function(self)
  local menu = self

  --If there are auxiliary menus, start them up
  if menu.aux_menus then
    for i, aux_menu in pairs(menu.aux_menus) do
      if sol.menu.is_started(aux_menu) then sol.menu.stop(aux_menu) end
      sol.menu.start(menu, aux_menu)
    end
  end

  --Initialize cursor index (using a base 1 system to match list indexes)
  if not menu.cursor_index then menu.cursor_index = 1 end

  if not menu.top_visible_row or not menu.view_offset then
    menu.top_visible_row = 1
    menu.view_offset = 0
  end

  --menu.view_surface is the surface that will display
  --part of the grid_surface for viewing.
  local view_w, view_h
  view_w = math.ceil(menu.edge_spacing * 2 + menu.cell_spacing * (menu.total_columns - 1) + menu.cell_width * menu.total_columns)
  view_h = math.ceil(menu.edge_spacing * 2 + menu.cell_spacing * (menu.visible_rows - 1) + menu.cell_height * menu.visible_rows)
  menu.view_surface = sol.surface.create(view_w, view_h)
  menu.width, menu.height = view_w, view_h

  --menu.grid_surface is the surface that will hold the
  --entire grid of objects.
  local grid_w, grid_h
  grid_w = math.ceil(menu.edge_spacing * 2 + menu.cell_spacing * (menu.total_columns - 1) + menu.cell_width * menu.total_columns)
  grid_h = (menu.edge_spacing * 2) + (menu.cell_spacing * (menu.total_rows - 1)) + (menu.cell_height * menu.total_rows)
  --the total grid should at least be the size specified by the config, even if there's not enough total items to ever fill it
  if grid_w < view_w then grid_w = view_w end
  if grid_h < view_h then grid_h = view_h end
  menu.grid_surface = sol.surface.create(grid_w, grid_h * 2) --just doubling the grid's height just in case you have a lot of line breaks
  menu.grid_surface:fill_color(menu.background_color)
  if menu.background_png then
    menu.background_surface = sol.surface.create(menu.background_png)
  end
  if menu.background_9slice_config then
    --If configured, calculate size of background from grid itself:
    if menu.background_9slice_config.calc_from_grid then
      local tile_size = menu.background_9slice_config.tile_width or 16
      menu.background_9slice_config.width = math.ceil(view_w / tile_size) * tile_size
      menu.background_9slice_config.height = math.ceil(view_h / tile_size) * tile_size
    end
    menu.background_surface = bg_9slice_manager.get_surface(menu.background_9slice_config)
  end

 --Make a surface for the cursor
  menu.cursor_surface = sol.surface.create(grid_w, grid_h * 2) --doubling the cursor surface's height just in case
  menu.cursor = sol.sprite.create(menu.cursor_style)

  --Make up and down arrows to indicate if scrolling is possible
  menu.scroll_arrow_surface = sol.surface.create(view_w, view_h + 16)
  menu.scroll_up_arrow = sol.sprite.create(menu.scroll_arrow_style)
  menu.scroll_up_arrow:set_direction(1)
  menu.scroll_down_arrow = sol.sprite.create(menu.scroll_arrow_style)
  menu.scroll_down_arrow:set_direction(3)

  --Make a surface the menu can use to draw effects (will be managed by each implementation of this menu)
  menu.fx_surface = sol.surface.create(view_w, view_h)

  --Make a surface to contain all other surfaces, to apply movement and opacity to:
  menu.base_surface = sol.surface.create()

  menu:update_objects()
  menu:update_surface()

  --Fade in if configured:
  if menu.fade_in_speed then
    menu:fade_in(menu.fade_in_speed)
  end

end)



function menu_prototype:update_objects()
  local menu = self
  --Resolve which items should be displayed and update menu.displayed_objects
  menu.displayed_objects = {}
  local i = 1
  for _, object in pairs(menu.allowed_objects) do --TODO: should this be pairs or ipairs?
    local displayed = false
    if object.line_break then
      object.hidden = true
      displayed = true
    elseif object.display_function == "_item" then
      --special value for convenience, assume it is an equipment item
      displayed = sol.main.get_game():has_item(object.name)
    elseif object.display_function then
      displayed = object.display_function(object)
    else
      displayed = true
    end
    if displayed then
      menu.displayed_objects[i] = object
      --If object is a line break, and previous object was not, we'll need to insert a few more blank objects in here
      if object.line_break and not (menu.displayed_objects[i-1].line_break) then
        local skipped_cells = (i % menu.total_columns)
        for j = 1, skipped_cells do
          menu.displayed_objects[i] = {hidden = true}
          if j < skipped_cells then i = i + 1 end
        end
      end
      --Provide defaults for any necessary object parameters
      if object.text and not object.text_offset then object.text_offset = {x = 0, y = 0} end
      --Update menu parameters
      i = i + 1
    end
  end
  --Set menu.displayed_num_cells (total cells that can be navigated by cursor) and menu.displayed_rows (total rows that can be navigated by cursor)
  --Add some extra, empty cells if there are an uneven number of filled cells, to fill out the bottom row
  local num_uneven_cells = #menu.displayed_objects % menu.total_columns
  local num_filler_cells = menu.total_columns - num_uneven_cells
  if num_uneven_cells == 0 then num_filler_cells = 0 end
  local max_cells = menu.total_columns * menu.visible_rows
  local min_cells = #menu.displayed_objects + num_filler_cells
  menu.displayed_num_cells = math.max(max_cells, min_cells)
  menu.displayed_rows = math.max(menu.visible_rows, math.ceil(menu.displayed_num_cells / menu.total_columns))
  local highest_filled_row = min_cells / menu.total_columns
  --If the number of displayed objects is less than menu.displayed_rows, you'll be able to scroll an empty row, which is weird 
  if (highest_filled_row) < menu.displayed_rows then
    menu.displayed_num_cells = min_cells
    menu.displayed_rows = highest_filled_row
  end

  menu:update_object_sprites()
end


function menu_prototype:update_object_sprites()
  local menu = self
  local cell_x, cell_y = menu.edge_spacing, menu.edge_spacing
  local i = 1
  menu.grid_surface:clear()
  menu.grid_surface:fill_color(menu.background_color)
  for _, object in pairs(menu.displayed_objects) do
    local sprite
    local text_surface
    if object.sprite then
      if object.sprite == "_item" then
        sprite = sol.sprite.create("entities/items")
        sprite:set_animation(object.name)
      else
        sprite = sol.sprite.create(object.sprite)
        if object.animation then sprite:set_animation(object.animation) end
      end
      if object.sprite_shader then
        sprite:set_shader(sol.shader.create(object.sprite_shader))
      end
    end
    if object.text or object.text_config or object.text_function then
      local config = object.text_config or {}
      config.font = config.font or default_settings.font
      config.font_size = config.font_size or default_settings.font_size
      text_surface = sol.text_surface.create(config)
      if not object.text_offset then
        object.text_offset = { x = 0, y = 0}
      end
      if object.text_key then text_surface:set_text_key(object.text_key) end
      if object.text_function then text_surface:set_text(object.text_function()) end
      if object.text then text_surface:set_text(object.text) end
    end
    local cell_surface = sol.surface.create(menu.cell_width, menu.cell_height)
    cell_surface:fill_color(menu.cell_color)
    if menu.cell_png then
      local cell_png = sol.surface.create(menu.cell_png)
      cell_png:draw(cell_surface)
    end
    if sprite then
      if object.sprite_offset then
        sprite:draw(cell_surface, object.sprite_offset.x, object.sprite_offset.y)
      else
        sprite:draw(cell_surface, menu.cell_width / 2, menu.cell_height - 8)
      end
    end
    if text_surface then
      text_surface:draw(cell_surface, object.text_offset.x, object.text_offset.y)
    end
    --Draw the cell
    if not object.hidden then
      if object.on_pre_draw then
        object.on_pre_draw(object, cell_surface, sprite, text_surface)
      end
      cell_surface:draw(menu.grid_surface, cell_x, cell_y)
      --Allow objects to define a post-draw event
      if object.on_post_draw then
        object.on_post_draw(object, cell_surface)
      end
      cell_x = cell_x + menu.cell_width + menu.cell_spacing
    end

    --If i divided by the number of columns has no remainder
    --then the next cell is the start of a new row.
    if i % menu.total_columns == 0 then
      --When the end of a row is drawn, the cell_x should be 
      --reset to only include the edge spacing.
      cell_x = menu.edge_spacing
      cell_y = cell_y + menu.cell_height + menu.cell_spacing
    end
    i = i + 1
  end

  menu:update_surface()
end


function menu_prototype:update_surface()
  local menu = self
  menu.view_surface:clear()
  menu.cursor_surface:clear()
  menu.scroll_arrow_surface:clear()
  local cursor_coord_x, cursor_coord_y = menu:get_cursor_coordinates()
  cursor_coord_x = (cursor_coord_x - 1) * (menu.cell_width + menu.cell_spacing) + menu.edge_spacing
  cursor_coord_y = (cursor_coord_y - 1) * (menu.cell_height + menu.cell_spacing) + menu.edge_spacing
  --Draw cursor
  if not menu.unfocused then
    menu.cursor:draw(menu.cursor_surface, cursor_coord_x + menu.cursor_offset_x, cursor_coord_y + menu.cursor_offset_y)
  end
  menu.grid_surface:draw(menu.view_surface, 0, menu.view_offset * -1)
  menu.cursor_surface:draw(menu.view_surface, 0, menu.view_offset * -1)
  --Draw scroll arrows
  if menu.top_visible_row > 1 then
    menu.scroll_up_arrow:draw(menu.scroll_arrow_surface, menu.width / 2, 8)
  end
  if menu.top_visible_row + menu.visible_rows <= menu.displayed_rows then
    menu.scroll_down_arrow:draw(menu.scroll_arrow_surface, menu.width / 2, menu.height + 14)
  end
  --Notify aux menus of update
  menu:notify_aux_menus()
end


function menu_prototype:notify_aux_menus()
  for i, aux_menu in pairs(self.aux_menus) do
    aux_menu:notify(self)
  end
end


function menu_prototype:get_cursor_coordinates()
  local menu = self
  local coord_x = (menu.cursor_index - 1) % menu.total_columns + 1
  local coord_y = math.floor((menu.cursor_index - 1) / menu.total_columns) + 1
  return coord_x, coord_y
end


function menu_prototype:get_index_from_coordinates(x, y)
  local menu = self
  local index = (y - 1) * menu.total_columns + x
  return index
end


function menu_prototype:get_selected_object()
  return self.displayed_objects[self.cursor_index]
end


function menu_prototype:move_cursor(direction)
  local menu = self
  local new_index
  local coord_x, coord_y = menu:get_cursor_coordinates()

  --Right, but loop around
  if direction == "right" and (coord_x == menu.total_columns) and (menu.cursor_edge_behavior == "loop") then
    new_index = menu.cursor_index - menu.total_columns + 1
  --Normal right
  elseif direction == "right" then
    new_index = menu.cursor_index + 1
  --at the top of the grid, up means to focus on the parent menu if there is one
  elseif direction == "up" and (coord_y == 1) and menu.is_child then
    menu:unfocus()
  elseif direction == "up" then
    new_index = menu.cursor_index - menu.total_columns
  --Left, but loop around
  elseif direction == "left" and (coord_x == 1) and (menu.cursor_edge_behavior == "loop") then
    new_index = menu.cursor_index + menu.total_columns - 1
  elseif direction == "left" then
    new_index = menu.cursor_index - 1
  elseif direction == "down" then
    new_index = menu.cursor_index + menu.total_columns
  end

  --If the new index is with bounds, update the cursor index
  if new_index and (new_index > 0) and (new_index <= menu.displayed_num_cells) then
    menu.cursor_index = new_index
    if menu.cursor_sound then sol.audio.play_sound(menu.cursor_sound) end
  --if we're in increment style and we've just moved right past the last index, move to the first index
  elseif new_index == menu.displayed_num_cells + 1 and (menu.cursor_edge_behavior == "increment") then
    menu.cursor_index = 1
  --if we're in increment style and we've just moved left past the first index, move to the last index:
  elseif new_index == 0 and (menu.cursor_edge_behavior == "increment") then
    menu.cursor_index = menu.displayed_num_cells
  --If we've moved down past the bottom, loop back to the top
  elseif new_index and new_index > menu.displayed_num_cells then
    menu.cursor_index = menu:get_index_from_coordinates(coord_x, 1)
  --If we've above the top, loop down to the bottom
  elseif new_index and new_index < 1 then
    menu.cursor_index = menu:get_index_from_coordinates(coord_x, menu.displayed_rows)
  end

  --Scroll, if necessary
  coord_x, coord_y = menu:get_cursor_coordinates()
  local bottom_vis_row = menu.top_visible_row + menu.visible_rows - 1
  if coord_y < menu.top_visible_row then
    local difference = menu.top_visible_row - coord_y
    menu:scroll(-1, difference)
  elseif coord_y > menu.top_visible_row + menu.visible_rows - 1 then
    local difference = coord_y - bottom_vis_row
    menu:scroll(1, difference)
  end
  menu:update_surface()
end



function menu_prototype:scroll(direction, num_rows) --for direction, up is -1, down is 1
  local menu = self
  num_rows = num_rows or 1
  local scroll_speed = 250
  menu.top_visible_row = menu.top_visible_row + (1 * direction) * (num_rows)
  local displacement = (menu.cell_height + menu.cell_spacing) * direction * (num_rows)
  --[[
  if menu.scroll_timer then menu.scroll_timer:stop() end
  --add previous unfinished scroll to next scroll
  if menu.target_offset and (menu.target_offset ~= menu.view_offset) then
    displacement = displacement - (menu.view_offset - menu.target_offset)
  end
  menu.target_offset = menu.view_offset + displacement
  menu.scroll_timer = sol.timer.start(menu, 1000 / scroll_speed, function()
    if menu.view_offset ~= menu.target_offset then
      menu.view_offset = menu.view_offset + 1 * direction
      menu:update_surface()
      return true
    end
  end)
  --]]
  menu.view_offset = menu.view_offset + displacement
  menu:update_surface()
end


function menu_prototype:react_to_parent_menu_scroll(direction)
--[[
  local menu = self
  local x, y = menu:get_cursor_coordinates()
  if direction == "right" then
    x = 1
  elseif direction == "left" then
    x = math.min(menu.total_columns, menu.displayed_num_cells)
  end
  local new_index = menu:get_index_from_coordinates(x, y)
  menu.cursor_index = math.min(new_index, menu.displayed_num_cells)
  menu:update_surface()
--]]
  --Note: above implementation makes more sense for flipping through a menu side-to-side.
  --Below, new implementation makes more sense for changing categories with L/R, which is what I expect to be most category flipping
  local menu = self
  menu.cursor_index = 1
  menu:update_surface()
end



menu_prototype:register_event("on_draw", function(self, screen)
  local menu = self
  if self.background_surface then
    self.background_surface:draw(self.base_surface, self.origin_x + menu.background_offset.x, self.origin_y + menu.background_offset.y)
  end
  self.view_surface:draw(self.base_surface, self.origin_x, self.origin_y)
  self.scroll_arrow_surface:draw(self.base_surface, self.origin_x, self.origin_y - 8)
  self.fx_surface:draw(self.base_surface, self.origin_x, self.origin_y)
  self.base_surface:draw(screen, 0, 0)
end)


menu_prototype:register_event("on_command_pressed", function(self, command)
  local menu = self
  local handled = false

  --Allow menus to override default actions
  if menu.default_command_overrides and menu.default_command_overrides[command] then
    return false
  end

  --not a child menu:
  if not menu.is_child then
    if (command == "right") or (command == "up") or (command == "left") or (command == "down") then
      self:move_cursor(command)
      handled = true
    end

  --is a child menu, don't allow looping around
  elseif menu.is_child and not menu.category_scroll_lock then
    local coord_x, coord_y = menu:get_cursor_coordinates()
    if menu.unfocused then
      if (command == "down") then
        menu:focus()
      end
    elseif (command == "right") and ((coord_x == menu.total_columns)) then
      handled = false
    elseif (command == "left") and (coord_x == 1) then
      handled = false
    elseif (command == "right") or (command == "up") or (command == "left") or (command == "down") then
      self:move_cursor(command)
      handled = true
    end

  elseif menu.is_child and menu.category_scroll_lock then
    local coord_x, coord_y = menu:get_cursor_coordinates()
    if menu.unfocused then
      if (command == "down") then
        menu:focus()
        handled = true
      end
    elseif (command == "right") or (command == "up") or (command == "left") or (command == "down") then
      self:move_cursor(command)
      handled = true
    end

  end
  return handled
end)


--Avoid analog stick wildly jumping
if sol.main.old_controls_version or ( tonumber(sol.main.get_solarus_version():match("(%d+.%d+)")) < 1.7 ) then
  function menu_prototype:on_joypad_axis_moved(axis,state)
    local menu = self
    menu.joy_avoid_repeat = menu.joy_avoid_repeat or {-2, -2}
    local handled = menu.joy_avoid_repeat[axis % 2] == state
    menu.joy_avoid_repeat[axis % 2] = state

    if handled then return handled end
  end
end


function menu_prototype:get_fx_surface()
  return self.fx_surface
end


function menu_prototype:unfocus()
  local menu = self
  menu.unfocused = true
  if menu.cursor_sound then sol.audio.play_sound(menu.cursor_sound) end
  menu:update_surface()
end


function menu_prototype:focus()
  local menu = self
  menu.cursor_index = menu:get_index_from_coordinates(1, menu.top_visible_row)
  if menu.cursor_sound then sol.audio.play_sound(menu.cursor_sound) end
  menu.unfocused = false
  menu:update_surface()
end


function menu_prototype:start_submenu(context, submenu)
  --Starts a submenu, and closes the current menu. The submenu can use submenu:quit_to_parent() to re-open the parent menu.
  assert(context, "Cannot start submenu, bad argument #1 to 'start_submenu', context needed (either map, game, sol.main, or table)")
  assert(submenu, "Bad argument #2 to 'start_submenu', submenu needs to be provided and you just provided the context")
  assert(submenu.set_parent_menu, "Cannot start submenu. Provided submenu does not have a 'set_parent_menu(parent_context, parent_menu) function")
  local menu = self
  submenu:set_parent_menu(context, menu)
  sol.menu.start(context, submenu, true)
  sol.menu.stop(menu)
end


function menu_prototype:set_parent_menu(parent_context, parent_menu)
  local menu = self
  assert(type(parent_menu) == "table", "Bad argument #1 to 'set_parent_menu' (menu expected)")
  assert(parent_context, "Bad argument #2 to 'set_parent_menu' (menu context expected)")
  menu.parent_menu = parent_menu
  menu.parent_context = parent_context
end


function menu_prototype:quit_to_parent()
  local menu = self
  assert(menu.parent_menu and menu.parent_context, "Cannot quit to parent menu, requires first calling submenu:set_parent_menu(parent_menu, parent_menu_context)")
  sol.menu.stop(menu)
  sol.menu.start(menu.parent_context, menu.parent_menu)
end


return grid_menu