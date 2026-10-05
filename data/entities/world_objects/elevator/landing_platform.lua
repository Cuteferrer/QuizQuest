--[[
Created by Max Mraz, licensed MIT
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite
local ground_type

function entity:on_created()
  sprite = entity:get_sprite()
  ground_type = entity:get_property("ground_type") or "traversable"
  if sprite then
    entity:set_modified_ground(ground_type)
  end
end


function entity:open()
  if sprite then
    sprite:set_animation("opening")
    entity:set_modified_ground"empty"
  end
end

function entity:close()
  if sprite then
    sprite:set_animation("closing", function()
      sprite:set_animation"closed"
    end)
    entity:set_modified_ground(ground_type)
  end
end
