--[[
Created by Max Mraz, licensed MIT
Default config for Trillium Dialog system, edit as you please
NOTE: font and font_size are not included here. This is intentional. You should be setting your font in language_manager, because different languages will require different fonts
If you want to do something cute where there's different fonts at different times like in Undertale, you'll have to work that in yourself. There's a reason Undertale is only in English and Japanese
--]]



local config = {
  --General settings
  origin_x = 32, --position of the dialog box
  origin_y = 150,
  width = 352,
  height = 80,
  visible_lines = 3,
  character_delay = 20,

  --Font / Text
  text_offset = {x = 16, y = 16},
  default_font_color = {250,230,190},

  --Sound
  vox_blips = {
    "vox_blips/bloop_1",
    "vox_blips/bloop_2",
    "vox_blips/bloop_3",
    "vox_blips/bloop_4",
    "vox_blips/bloop_5",
    "vox_blips/bloop_6",
    "vox_blips/bloop_7",
  },
  vox_blip_frequency = 70, --vox blips will not occur faster than this, otherwise they play per character appearing

  --Background
  --bg_source = "menus/panel_blocks/general.png", --if bg_type == "9slice" then this is the 9slice source png, otherwise it's a static PNG to display as the text box bg
  --bg_type = "png", --options are "9slice" or "png"
  --bg_source = "hud/dialog_box_background.png",
  bg_type = "9slice",
  slice_width = 16,
  slice_height = 16,
  slice_repeat_style = "tile", --can be "tile" or "scale"

  --Choices
  choice_offset = 8, --How far indented choices are compared to normal text offset
  cursor_sprite = "menus/arrow",
  cursor_sound = "cursor",
  cursor_offset = {x = 16, y = 3},

  --Name box
  name_box = {
    offset_x = 0, --offset from origin_x, origin_y
    offset_y = -24,
    text_indent = 8,
    font_color = {220,200,160},
    width = 128,
    height = 24,
    bg_type = "9slice",
    bg_source = "menus/panel_blocks/small.png",
    slice_width = 8,
    slice_height = 8,
    repeat_style = "tile",
  },
}

return config
