--[[
Cutscene functions
Hides HUD, prevents pause, etc.
--]]

local map_meta = sol.main.get_metatable"map"

--Starts a "cutscene" mode, hiding the HUD, preventing pause, etc.
function map_meta:start_cutscene()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()

  map.cutscene_enabled = true
  game:set_hud_enabled(false)
  game:set_pause_allowed(false)
  hero:stop_dash()
  hero:freeze()
end

--Stops "cutscene mode"
function map_meta:stop_cutscene()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()

  map.cutscene_enabled = false
  game:set_hud_enabled(true)
  game:set_pause_allowed(true)
  hero:unfreeze()
  
end

function map_meta:is_cutscene_enabled()
  return self.cutscene_enabled
end
