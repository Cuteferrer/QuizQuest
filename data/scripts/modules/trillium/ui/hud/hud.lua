--HUD Script Steps

-- Usage:
-- require("scripts/modules/trillium/ui/hud/hud")

--Get HUD config:
local hud_elements_config = require("scripts/modules/trillium_config/ui/hud_config")
local screen_w, screen_h = sol.video.get_quest_size()


local function destroy_hud(game)
  if not game.get_hud then return end --hud not initialized
  local hud = game:get_hud()
  if hud then
    for _, element_menu in pairs(hud.elements) do
      sol.menu.stop(element_menu)
    end
    hud.elements = {}
  end
end


-- Creates and runs a HUD for the specified game.
local function init_hud(game)

  --Create HUD table:
  local hud = {
    elements = {},
    enabled = false,
  }


  local function do_to_each_menu(callback)
    for _, element_menu in pairs(hud.elements) do
      callback(element_menu)
    end
  end

  --Build HUD Menus:
  for _, config in pairs(hud_elements_config) do
    --Convenience: translate negative X or Y coordinates automatically.
    --Arguably, it could be on each HUD element to do this iteself, but it's a common use
    if (config.x and config.x < 0) then config.x = screen_w + config.x end
    if (config.y and config.y < 0) then config.y = screen_h + config.y end
    local element_builder = require(config.menu_script)
    local element_menu = element_builder:new(game, config)
    table.insert(hud.elements, element_menu)
  end


  function hud:is_enabled()
    return hud.enabled
  end

  --Return HUD
  function game:get_hud() return hud end


  function hud:set_enabled(enabled_bool)
    if enabled_bool == hud:is_enabled() then return end --return if the hud is already as desired
    hud.enabled = enabled_bool
    if enabled_bool == true then
      do_to_each_menu(function(menu)
        sol.menu.start(game, menu)
      end)
    else
      do_to_each_menu(function(menu)
        sol.menu.stop(menu)
      end)
    end
  end


  function game:set_hud_enabled(enabled_bool)
    hud:set_enabled(enabled_bool)
  end


  local function on_hud_paused(game)
    do_to_each_menu(function(menu)
      if menu.on_paused then menu:on_paused() end
    end)
    --Hide HUD when paused:
    hud.pause_disabled = true
    hud:set_enabled(false)
  end


  local function on_hud_unpaused(game)
    do_to_each_menu(function(menu)
      if menu.on_unpaused then menu:on_unpaused() end
    end)
    --Show HUD if hidden when pausing:
    if hud.pause_disabled then
      hud:set_enabled(true)
    end
    hud.pause_disabled = false
  end

  game:register_event("on_paused", function() on_hud_paused(game) end)
  game:register_event("on_unpaused", function() on_hud_unpaused(game) end)

  -- Start the HUD.
  hud:set_enabled(true)

end

-- Init HUD when game starts:
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(game)
  --Destroy existing hud:
  destroy_hud(game)
  --Init new hud:
  init_hud(game)
end)
