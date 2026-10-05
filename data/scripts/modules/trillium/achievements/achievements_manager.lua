--[[
Created by Max Mraz, licensed MIT

Generic manager for achievements- will call to Steam or other specific achievement systems
Reads achievement IDs from scripts/modules/trillium_config/system_data/achievements, and saves them in a savegame variable "achievement_status_{achievement ID}"
Functions should only be called when the game is running, as achievements are stored as savegame values

Usage to unlock an achievement:
sol.achievements.unlock(achievement_id)

Some achievements aren't easy to trigger via a discrete call, like checking to see if every weapon has been completed.
Modify the script at scripts/modules/trillium_config/system_data/achievement_requirement_checker
This is a messy function that can check whether all conditions are met to trigger an achievement.
In cases where an achievement MIGHT be triggered, call either:
sol.achievements.requirement_checker.check(ach_id)
sol.achievements.requirement_checker.check_all()


--]]

local game_meta = sol.main.get_metatable"game"

sol.achievements = {}
sol.achievements.steam_impl = {} --have a seperate section of this code for Steam implementation, so it can be easily removed/ignored when released on other platforms
local ach_list = require"scripts/modules/trillium_config/system_data/achievements" or {}
sol.achievements.requirement_checker = require"scripts/modules/trillium_config/system_data/achievement_requirement_checker"

--Warning if no achievements configured:
if (#ach_list == 0) then
  print("Warning: no achievements configured at scripts/modules/trillium_config/system_data/achievements.lua")
end


--When game starts, make sure unlocked achievements are updated, run again every 30s afterward
game_meta:register_event("on_started", function(game)
  --NOTE: cannot start immediately, because not all equipment items have been initialized yet
  --Some items can be initialized by a separate script, which also runs on game starting
  sol.timer.start(game, 100, function()
    sol.achievements.update()
    sol.achievements.requirement_checker.check_all()
    return 30000
  end)
end)


--Make sure all unlocked achievements are updated, useful in case of connection problems
function sol.achievements.update()
  --print"Updating Achievement"
  local game = sol.main.get_game()
  for _, ach_id in ipairs(ach_list) do
    --print("Achievement ID:", ach_id, "Status:", game:get_value("achievement_status_" .. ach_id))
    if game:get_value("achievement_status_" .. ach_id) then sol.achievements.unlock(ach_id) end
  end
end


function sol.achievements.get_achievement_status(ach_id)
  local game = sol.main.get_game()
  return game:get_value("achievement_status_" .. ach_id)
end


--Unlock a single achievement
function sol.achievements.unlock(ach_id)
  local game = sol.main.get_game()
  if not game:get_value("achievement_status_" .. ach_id) then
    --print("Info: Unlocked Achievement:", ach_id)
    game:set_value("achievement_status_" .. ach_id, true)
  else
    --print("Achievement " .. ach_id .. " already unlocked")
  end
  --Steam Achievements
  sol.achievements.steam_impl.unlock_ach(ach_id)
end


--Queue boss achievement
--I HATE how the trophy/achievement overlay pops right when you beat a boss, this will queue the achievement for a bit
function sol.achievements.queue_unlock(ach_id)
  local DELAY = 4000
  local game = sol.main.get_game()
  game.queued_achievements = game.queued_achievements or {}
  game.queued_achievements[ach_id] = ach_id
  sol.timer.start(game, DELAY, function()
    sol.achievements.unlock(ach_id)
    game.queued_achievements[ach_id] = nil
  end)
end

--Batch unlock any queued achievements when you close the game (so if you save+quit in the seconds while an achievement is queued, you don't lock yourself out of it)
game_meta:register_event("on_finished", function(game)
  if game.queued_achievements then
    for _, ach_id in pairs(game.queued_achievements) do
      sol.achievements.unlock(ach_id)
    end
  end
end)



--Reset all achievements. Useful for development
function sol.achievements.reset_all()
  local game = sol.main.get_game()
  for i, ach_id in ipairs(ach_list) do
    game:set_value("achievement_status_" .. ach_id, nil)
  end
  --Reset in Steam
  sol.achievements.steam_impl.reset_all_ach()
  print"All achievements reset"
end


--Print all unlocked achievements. For debugging purposes:
function sol.achievements.print_all()
  for _, ach_id in ipairs(ach_list) do
    print("Ach ID: ", ach_id, " .................... ", sol.achievements.get_achievement_status(ach_id))
  end
end


--Steam Impl--------------------------------------------------------------------------------

function sol.achievements.steam_impl.unlock_ach(ach_id)
  if sol.steam and sol.steam.unlock_achievement then
    sol.steam.unlock_achievement(ach_id)
  end
end


function sol.achievements.steam_impl.reset_all_ach()
  if sol.steam and sol.steam.userStats and sol.steam.userStats.resetAllStats then
    sol.steam.userStats.resetAllStats(true)
  end
end



