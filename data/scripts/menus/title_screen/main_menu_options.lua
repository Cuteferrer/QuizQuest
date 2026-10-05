--[[
Returns an array of options for the main menu to show
This can differ depending on build conf settings
For example, console builds cannot show a "quit" option,
or demo builds might show a "wishlist" option.
--]]

local manager = {}
local build_conf = sol.main.get_build_conf()

function manager.get_options()
  if build_conf.console then
    return {
      "continue",
      "load",
      "new_game",
      "options",
    }
  else
    return {
      "continue",
      "load",
      "new_game",
      "options",
      "quit"
    }
  end
end

return manager
