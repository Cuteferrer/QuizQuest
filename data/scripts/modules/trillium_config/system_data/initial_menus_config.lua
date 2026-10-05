--[[
Menu Config: list all menus here as a table with these values:
  {
    id = "path/to/menu",
    splash = true_if_menu_is_splashscreen,
  }
Config also takes a "music" key, which will start playing music alongside the first menu
--]]

return {
  {id = "scripts/modules/trillium/core/language/language_menu"},
  --{id = "scripts/menus/start_game"},
  {id = "scripts/menus/title_screen/top_menu"},
  music = "title_thoughtful",
}
