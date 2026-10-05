--[[
By Max Mraz, licensed MIT
Trillium Dialog system. See docs for usage.
--]]

local game_meta = sol.main.get_metatable"game"
local dialog_menu = require("scripts/modules/trillium/dialog/libs/dialog_menu")
local overrun_checker = require("scripts/modules/trillium/dialog/libs/overrun_checker")


--[[Start dialog
function game_meta:start_dialog(dialog_id, info, callback)

end
--]]


game_meta:register_event("on_dialog_started", function(game, dialog, info)
  local dialog_id = dialog.id
  if info == nil then
    info = {}
  end
  dialog_menu.dialog = sol.language.get_dialog(dialog_id)
  dialog_menu.info = info

  local hero = game:get_hero()
  if hero:get_animation() == "walking" then
    hero:set_animation("stopped")
  end

  --Suspend game if not already suspended
  if not game:is_suspended() then
    dialog_menu.activation_suspended_game = true
    game:set_suspended(true)
  else
    dialog_menu.activation_suspended_game = false
  end

  --Hide HUD
  local hud = game:get_hud()
  if hud:is_enabled() then
    hud:set_enabled(false)
    dialog_menu.activation_disabled_hud = true
  else
    dialog_menu.activation_disabled_hud = false
  end

  sol.menu.start(game, dialog_menu)
end)


-- End dialog
game_meta:register_event("on_dialog_finished", function(game, dialog)
  if sol.menu.is_started(dialog_menu) then
    sol.menu.stop(dialog_menu)
  end
  --Unsuspend the game if the dialog suspended it initially
  if dialog_menu.activation_suspended_game then
    dialog_menu.activation_suspended_game = nil
    game:set_suspended(false)
  end
  --Show HUD if we hid it
  if dialog_menu.activation_disabled_hud then
    dialog_menu.activation_disabled_hud = nil
    game:get_hud():set_enabled(true)
  end
end)

