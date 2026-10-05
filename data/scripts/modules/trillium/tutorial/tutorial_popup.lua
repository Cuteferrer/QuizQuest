--[[
By Max Mraz, licensed MIT
Pop a tutorial message. Messages are just dialogs with an accompanying graphic for illustration
Call with game:start_tutorial(tutorial_id)
If the player has already seen the tutorial, nothing will happen - Unless you pass a second argument, to force the tutorial to play anyway.

To set up the necessary pieces to show a tutorial, you just need:
A dialog: menus.tutorial.tutorial_id
An illustration to accompany it at: sprites/menus/tutorial/illustrations/tutorial_id.png (optional)
--]]

--Config settings:
local illustration_bottom_y = 145 --where the bottom of the illustration will be (you want this to line up near the top of your dialog box)

local game_meta = sol.main.get_metatable"game"
local menu = {}

local screen_width, screen_height = sol.video.get_quest_size()
local menu_surface = sol.surface.create()
local darken_surface = sol.surface.create()
darken_surface:fill_color({0,0,0,100})

function game_meta:start_tutorial(id, skip_override)
  local game = self
  local tut_savegame_id = "tutorial_watched_" .. id
  if game:get_value(tut_savegame_id) and not skip_override then
    --Already seen tutorial, skip it
    return
  end
  --If option setting is selected, skip tutorials:
  if game:get_value("option_show_tutorials") == false then return end

  --wait for hero to be in free state to start tutorial:
  local hero = game:get_hero()
  sol.timer.start(game, 0, function()
    local state, stob = hero:get_state()
    if state == "custom" then state = stob:get_description() end
    if hero:get_state() == "free" or state == "dash_recovery" then
      game:set_value(tut_savegame_id, true)
      menu.tut_id = id
      if sol.menu.is_started(menu) then sol.menu.stop(menu) end
      sol.menu.start(game, menu)
    else
      return 20
    end
  end)
end


function menu:on_started()
  assert(menu.tut_id, "Cannot start a tutorial without an id")
  local game = sol.main.get_game()
  local id = menu.tut_id
  local illustration_id = "menus/tutorial/illustrations/" .. id .. ".png"
  local panel = sol.surface.create(illustration_id)
  menu_surface:clear()
  if panel then --if the illustration id isn't a PNG in the directory, we can still show the dialog
    local width, height = panel:get_size()
    local panel_x = (screen_width / 2) - (width / 2)
    local panel_y = illustration_bottom_y - height
    panel:draw(menu_surface, panel_x, panel_y)
  end

  assert(sol.language.get_dialog("menus.tutorial." .. id), "No tutorial dialog found with id: menus.tutorial." .. id )
  game:start_dialog("menus.tutorial." .. id, function()
    game:get_hero():unfreeze()
    sol.menu.stop(menu)
  end)

end


function menu:on_draw(dst)
  darken_surface:draw(dst)
  menu_surface:draw(dst)
end


return menu