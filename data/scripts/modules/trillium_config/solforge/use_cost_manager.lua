--[[
Created by Max Mraz, licensed MIT

Make any changes you'd like to the manager.can_use() function to allow/prevent a weapon from being used
This function should return a boolean to indicate whether the weapon can be used or not

For example, if you have a stamina system, you might check if the player has any stamina
Or if particular weapons require magic to use, you could check it here.

--]]


local manager = {}

function manager.can_use(item)
  local game = item:get_game()
  local can_use = true


  return can_use
end


return manager

