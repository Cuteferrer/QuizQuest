--[[
Created by Max Mraz, licensed MIT (but honestly, this is not licensable code, it's way too simple for that)
A little wall entity that enemies will not cross unless they're chasing the hero.
Allows them to have a space to wander randomly when not fighting, but keeps them from wandering too far
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_visible(false)
  entity:set_traversable_by("enemy", function(entity, enemy)
    if enemy.aggro then
      return true
    else
      return false
    end
  end)
end
