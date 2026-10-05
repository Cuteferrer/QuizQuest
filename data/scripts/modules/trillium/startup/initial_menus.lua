--[[
Written by Max Mraz, Licensed MIT
Shows a series of menus in the given order, useful for putting splash screens a language menu in front of the title screen
--]]

local menu_config = require("scripts/modules/trillium_config/system_data/initial_menus_config")



local manager = {}

local menu_list = {}
local on_top = false --false to allow the menu controls manager to continue to intercept and quash duplicate inputs

function manager:start()
  --If there is a music, play that:
  sol.timer.start(sol.main, 10, function()
    if menu_config.music then
      sol.audio.play_music(menu_config.music)
    end
  end)

  menu_list = {}

  if #menu_config <= 0 then --no menus to run:
    return
  end

  --Check if should skip splash_screens
  local skip_splashes = false
  if (sol.main.get_elapsed_time() > 3000) or sol.main.debug_mode then skip_splashes = true end

  --Load menus:
  for i, mcon in ipairs(menu_config) do
    if (skip_splashes and mcon.splash) then
      --Skip this menu
    else
      local menu = require(mcon.id)
      table.insert(menu_list, menu)
    end
  end

  --Make each menu in the list start the next:
  for i, menu in ipairs(menu_list) do
    function menu:on_finished()
      --If a game is already running, don't go to the next menu (probably this menu started the game)
      if sol.main.get_game() ~= nil then return end

      local next_menu = menu_list[i + 1]
      if next_menu ~= nil then
        sol.menu.start(sol.main, next_menu, on_top)
      end
    end

  end

  --Start first menu:
  sol.menu.start(sol.main, menu_list[1], on_top)

end


--Once a game starts, stop all these menus:
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(game)
  for _, menu in ipairs(menu_list) do
    sol.menu.stop(menu)
  end
end)


return manager

