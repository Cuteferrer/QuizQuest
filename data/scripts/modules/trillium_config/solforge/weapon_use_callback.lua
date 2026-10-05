--[[
Created by Jeff Cournoyer, licensed under the MIT License.
This script is meant to be a catch-all for effects one may want to
activate when weapons are used, in addition to the default effects 
present in the forge.lua file. This could be used for, as an example,
adding a flame tail sprite to the fire sword's swing. 
--]]

local weapon_use_manager = {}


  --Adds effects to the weapon when using the weapon.
  function weapon_use_manager:initiate_usage(item, attack)
    local game = item:get_game()
    local hero = game:get_hero()
    local map = game:get_map()


  end

return weapon_use_manager