--[[
Created by Max Mraz, licensed MIT
Messy function to check if an achievements requirements have been met, and if so, unlock it

Two available functions:
check(ach_id)  -- will check and unlock a single achievement
check_all()    -- will check requirements and unlock any that should be

It won't check for ALL achievements. Many (like defeating a boss) are just called manually (like from the map with that boss).
This is just for annoying things like "have you collected every weapon?"
--]]

local manager = {}
local ach_list = require"scripts/modules/trillium_config/system_data/achievements"


function manager.check_all()
  for _, ach_id in pairs(ach_list) do
    manager.check(ach_id)
  end
end


function manager.check(id)
  local game = sol.main.get_game()
  assert(game, "Can't check achievement requirements unless game is running")

  if id == "ach_test" then


  elseif id == "placeholder_to_copy" then
    if condition_met then
      sol.achievements.unlock(id)
    end


  end
end




return manager
