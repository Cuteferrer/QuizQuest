--[[
Created by Max Mraz, licensed MIT
loads the luasteam module and provides a few functions to utilize it
Depends on Trillium Achievements module to work
--]]


local function steam_init()
  print("Info: Initializing Steam features")
  sol.steam = require"luasteam"

  if not sol.steam.init() then
    error("Warning: Steam couldn't initialize")
    print("Warning: Could be missing luasteam.dll or steam_api64.dll from the directory with the game launcher or exe")
  end

  --Regularly check in with Steam:
  sol.timer.start(sol.main, 100, function()
    sol.steam.runCallbacks()
    return true
  end)

  --After a few ms, make sure we have a logged-in user.
  sol.timer.start(sol.main, 20, function()
    print("Info: Steam user ID:", sol.steam.user.getSteamID())
    assert(sol.steam.userStats.requestCurrentStats(), "Warning: No Steam user is logged in. Cannot do achievements and stuff")
  end)

  --Called when stats/achievements have been received from Steam server
  --Once this happens, we allow achievements activites to happen
  function sol.steam.userStats.onUserStatsReceived(data)
    sol.steam.can_use_stats = true
  end

  function sol.steam.unlock_achievement(ach_id)
    if sol.steam.can_use_stats then
      sol.steam.userStats.requestCurrentStats()
      if not sol.steam.userStats.setAchievement(ach_id) then
        --print("Warning: Could not update Steam achievement. Achievement ID: ", ach_id)
      end
      sol.steam.userStats.storeStats() -- shows overlay notification
    elseif not sol.steam.schedule_update_timer then
      --Can't use stats right now, schedule later update
      sol.steam.schedule_update_timer = sol.timer.start(sol.main, 3000, function()
        sol.steam.schedule_update_timer = nil
        sol.achievements.update()
      end)
    end
  end

end


--TODO: Create some build config file with information like whether it's a debug build and what target platform.
--In that file, put whether or not the build should expect to connect to Steam, and have this script check that config.
--That config file can get altered by CI/CD pipelines at build time to target different platforms
local connect_to_steam = true
local show_steam_connection_err = false

if connect_to_steam then
  --Call Initialize function in protected mode, so we can ignore this for other platforms
  local is_good, err = pcall(steam_init)

  if not is_good and show_steam_connection_err then
    print("Warning: Errors while initializing Steam:", err)
  elseif not is_good then
    print("Warning: could not initialize Steam")
  end
end

