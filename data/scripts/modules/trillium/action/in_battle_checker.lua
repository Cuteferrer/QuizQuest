--[[
Created by Max Mraz, licensed MIT
Checks if the player is currently fighting enemies

Allows stuff like not using stamina to dash if you're not fighting enemies, not allowing to swap in the inventory, etc.
--]]

local game_meta = sol.main.get_metatable"game"
local hero_meta = sol.main.get_metatable"hero"

local AGGRO_LOST_DISTANCE = 300


function game_meta.is_in_battle(game)
  return game:get_hero():is_in_battle()
end


function hero_meta.is_in_battle(hero)
  local map = hero:get_map()
  local in_battle = false
  for e in map:get_entities_by_type("enemy") do
    if e.aggro then
      if e:is_on_screen() or (e:get_distance(hero) < AGGRO_LOST_DISTANCE) then
        in_battle = true
        break
      end
    end
  end

  return in_battle
end
