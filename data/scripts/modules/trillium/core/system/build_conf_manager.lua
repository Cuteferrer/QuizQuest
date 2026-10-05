--[[
Manages a "build_conf.lua" file
This file is used for activating/deactivating features that might differ between builds
For example, a console build won't include an "exit" option in the main menu, or a steam build might include steam achievements
--]]

local build_conf_file = "build_conf" --we assume this is a .lua file

function sol.main.get_build_conf()
  local exists = sol.file.exists(build_conf_file .. ".lua")
  if exists then
    return require(build_conf_file)
  else
    print("Warning: No build conf file found at '" .. build_conf_file .. ".lua' - cannot use sol.main.get_build_conf()")
    return {}
  end
end