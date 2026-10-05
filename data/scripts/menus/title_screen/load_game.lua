local game_manager = require("scripts/menus/title_screen/game_manager")
local settings = sol.modules.get_object("settings_manager")

local menu = {}

local black = sol.surface.create()
black:fill_color{0,0,0}
local loading_icon = sol.sprite.create("menus/title_screen/loading_icon")
local iw, ih = loading_icon:get_size()
local vw, vh = sol.video.get_quest_size()
local ix, iy = (vw / 2) - (iw / 2), (vh / 2) - (ih / 2)

function menu:set_filename(filename)
  menu.filename = filename
end


function menu:on_started()
  assert(menu.filename, "No game was set for load_game menu va menu:set_filename()")
  local start_time = os.time()

  sol.timer.start(menu, 100, function()
    local game = game_manager:create(menu.filename)
    --print("Load menu, game created in: ", os.time() - start_time)
    settings.set_value("last_loaded_savefile", menu.filename)
    settings.save()
    sol.timer.start(menu, 200, function()
      game:register_event("on_started", function()
        sol.menu.stop(menu)
      end)
      game:start()
    end)
  end)
end


function menu:on_draw(dst)
  black:draw(dst)
  loading_icon:draw(dst, ix, iy)
end

return menu
