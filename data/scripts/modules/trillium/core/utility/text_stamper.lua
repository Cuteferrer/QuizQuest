--[[
Created by Max Mraz, licensed MIT
A function to print a given dialog onto a given surface; clears then returns the surface, now with the dialog printed on it
Usage:
sol.surface.stamp_text({
  dst_surface = some_surface_I_made,
  dialog_id = some.dialog.id,
  --other config options
})
--]]

sol.surface.stamp_text = function(config)
  local dst_surface = config.dst_surface
  local dialog_id = config.dialog_id
  local font, font_size, vert_spacing = sol.modules.get_object("language_manager"):get_menu_font()
  if config.font then font = config.font end
  if config.font_size then font_size = config.font_size end
  if config.vertical_spacing then vert_spacing = config.vertical_spacing end
  local offset_x, offset_y = config.offset_x or 0, config.offset_y or 0

  dst_surface:clear()

  --Test that the dialog exists:
  if not sol.language.get_dialog(dialog_id) then
    print("WARNING: trying to create a surface to display dialog, but dialog not found: " .. dialog_id)
    return
  end

  local dialog = sol.language.get_dialog(dialog_id).text
  local lines = {}
  for s in dialog:gmatch("[^\r\n]+") do
      table.insert(lines, s)
  end
  for i, line in ipairs(lines) do
    local line_surface = sol.text_surface.create{
      font = font,
      font_size = font_size,
      text = line,
      vertical_alignment = "top",
    }
    line_surface:draw(dst_surface, offset_x, offset_y + vert_spacing * (i - 1) )
  end
  return dst_surface
end
