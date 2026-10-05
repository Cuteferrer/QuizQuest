--Returns config information about language and fonts
--get_font functions return font name, font size, and vertical line spacing
local manager = {}

local default_language = "en"

function manager:get_default_language()
  return default_language
end


function manager:get_dialog_font(language)
  return "enter_command", 16, 16
end


function manager:get_menu_font(language)
  return "enter_command", 16, 16
end


function manager:get_hud_icons_font(language)
  return "enter_command", 16 --no vertical spacing in HUD icons
end


return manager

