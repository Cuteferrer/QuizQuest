--[[
Created by Max Mraz, licensed MIT
This script provides some functions to compare quest or solarus versions
If the game was last loaded with in earlier version, you can make changes to bring anything in line with the current version of the game code

Useage:
require("scripts/system/version_compatibility_checker").check_quest_compat()
  --this will run any necessary updates from marked versions (see table below)
--]]


local settings = sol.modules.get_object("settings_manager")
local manager = {}


--Table of version that, when updated to, need changes
--Key: version string
--Value: function, what to do if the previous version was below the marked version
local marked_versions = {

  ["0.3.9"] = function()
    --Reset controls to default, breaking changes:
    print("Version incompatibility: Resetting controls to default")
    sol.controls.get_controls_manager().reset_default_controls()
    --Reset save files, in case you were from before the level-up system
    print("Version incompatibility: Clearing existing save files")
    local savenames = {"save1.dat", "save2.dat", "save3.dat", "save4.dat"}
    for _, name in ipairs(savenames) do
      sol.file.rename(name, "incompatible_controls" .. name)
    end
  end,

}




-- Split version strings into table of components
local function split_version(version)
    local version_arr = {}
    for part in string.gmatch(version, "(%d+)") do
        table.insert(version_arr, tonumber(part))
    end
    return version_arr
end


--Checks if version a is earlier than version b
local function is_earlier(a, b)    
    local version_a = split_version(a)
    local version_b = split_version(b)
    -- Compare each component:
    for i = 1, math.max(#version_a, #version_b) do
        local part_a = version_a[i] or 0
        local part_b = version_b[i] or 0
        if part_a < part_b then
            return true   -- a is earlier than b
        elseif part_a > part_b then
            return false  -- a is later than b
        end
        -- If equal, continue to next component
    end
    return false  -- Versions are equal, so a is not earlier than b
end


local function is_equal(a, b)
  local is_equal = true
  local version_a = split_version(a)
  local version_b = split_version(b)
  -- Compare each component:
  if #version_a ~= #version_b then return false end
  for i = 1, math.max(#version_a, #version_b) do
    if version_a[i] ~= version_b[i] then
      is_equal = false
      break
    end
  end
  return is_equal
end

function manager.check_quest_compat()
  local current_version = sol.main.get_quest_version()
  local saved_version = settings.get_value("quest_version") or sol.main.get_quest_version()

  --Need to run operations if saved version is below any marked versions that current version is greater or equal to
  --We can probably assume the current version of the code is above ALL marked versions, because like... how else would we know to mark them lol
  --But still, to be thorough I guess
  for marked_version, callback in pairs(marked_versions) do
    if is_earlier(saved_version, marked_version) and ( is_earlier(marked_version, current_version) or is_equal(marked_version, current_version) ) then
      print("Updating game for version:", marked_version)
      callback()
    end
  end

  settings.set_value("quest_version", current_version)

end


return manager

