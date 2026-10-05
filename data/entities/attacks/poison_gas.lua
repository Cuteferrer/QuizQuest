--[[
Created by Max Mraz, licensed MIT
A cloud of poison gas. Heroes or enemies that enter the gas will build up a poison status effect if the status effect system is used, or otherwise take damage
Set default values below for poison amount, how long the cloud lasts, etc.
You can also set things like entity.duration, or entity.poison_frequency after the entity is created if you want some clouds to not use the default values: for example the hero has an item that creates a faster-acting gas cloud for enemies

Set entity.ignore_hero if you want the gas to not affect the hero.
Also, gas respects enemy.poison_immunity to not poison certain enemies
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local poison_frequency = 100
local poison_amount = 4
local enemy_poison_amount = 6
local duration = 1000

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_can_traverse(true)
  --entity:set_can_traverse_ground("wall", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)

  entity.poison_frequency = poison_frequency
  entity.hero_poison_amount = hero_poison_amount
  entity.enemy_poison_amount = enemy_poison_amount
  entity.duration = duration

  local sprite = entity:get_sprite()
  sprite:set_opacity(200)
  sprite:set_animation("growing", function()
    sprite:set_animation("stopped")
    sol.timer.start(entity, entity.duration, function()
      sprite:set_animation("dispersing", function() entity:remove() end)
    end)
  end)

  local collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other)
    if collided_entities[other] then return end
    collided_entities[other] = true
    sol.timer.start(entity, poison_frequency, function()
      collided_entities[other] = nil
    end)

    if other:get_type() == "hero" and not entity.ignore_hero then
      if other.build_up_status_effect then
        other:build_up_status_effect("poison", entity.hero_poison_amount)
      else
        game:remove_life(entity.hero_poison_amount)
        sol.audio.play_sound"hero_hurt"
      end
    elseif other:get_type() == "enemy" and not other.poison_immunity and not entity.ignore_enemies then
      if other.build_up_status_effect then
        other:build_up_status_effect("poison", entity.enemy_poison_amount)
      else
        other:remove_life(entity.enemy_poison_amount)
        sol.audio.play_sound"enemy_hurt"
      end
    end
  end)

end
