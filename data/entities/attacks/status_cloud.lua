--[[
Created by Max Mraz, licensed MIT
A cloud of status-effect causing gas. Heroes or enemies that enter the gas will build up a status effect if the status effect system is used, or otherwise take damage
Set default values below for amount, how long the cloud lasts etc.
You can also set things like entity.duration, or entity.status_frequency after the entity is created if you want some clouds to not use the default values: for example the hero has an item that creates a faster-acting gas cloud for enemies

Set entity.ignore_hero if you want the gas to not affect the hero.
Also, gas respects enemy.{status_type}_immunity to not affect certain enemies
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local i = 0 

local status_type = "burn"
local status_frequency = 100
local hero_status_amount = 4
local enemy_status_amount = 6
local hero_damage_amount = 0
local enemy_damage_amount = 0
local damage_frequency = 500
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

  entity.status_type = entity.status_type or status_type
  entity.status_frequency = status_frequency
  entity.hero_status_amount = hero_status_amount
  entity.enemy_status_amount = enemy_status_amount
  entity.duration = duration
  entity.hero_damage_amount = hero_damage_amount
  entity.enemy_damage_amount = enemy_damage_amount
  entity.damage_frequency = damage_frequency

  local sprite = entity:get_sprite()
  sprite:set_opacity(100)
  sprite:set_animation("growing", function()
    sprite:set_animation("stopped")
    sol.timer.start(entity, entity.duration, function()
      sprite:set_animation("dispersing", function() entity:remove() end)
    end)
  end)

  local collided_entities = {}

  sol.timer.start(entity, 10, function()
    entity:add_collision_test("sprite", function(entity, other)

      if collided_entities[other] then return end
      collided_entities[other] = true
      sol.timer.start(entity, entity.status_frequency, function()
        collided_entities[other] = nil
      end)

      --Inflict status
      --Hero:
      if other:get_type() == "hero" and not (entity.ignore_hero or entity.harmless_to_hero) then
        if other.build_up_status_effect and entity.status_type then
          other:build_up_status_effect(entity.status_type, entity.hero_status_amount or entity.status_amount)
        else
          --This should only ever get called if you're not using the status effect system
          game:remove_life(entity.hero_status_amount)
          sol.audio.play_sound"hero_hurt"
        end
        --Damage
        if entity.hero_damage_amount > 0 then
          if not other.status_cloud_damage_cooldown then
            other.status_cloud_damage_cooldown = true
            sol.timer.start(other, entity.damage_frequency, function()
              other.status_cloud_damage_cooldown =  false
            end)
            sol.audio.play_sound("hero_hurt_small")
            other:blood_splatter(self, 8)
            game:remove_life(entity.hero_damage_amount)
          end
        end
      --Enemy:
      elseif (other:get_type() == "enemy") and (not entity.ignore_enemies) and not (other[(entity.status_type or "") .. "_immunity"]) then
        if other.build_up_status_effect and entity.status_type ~= nil then
          other:build_up_status_effect(entity.status_type, entity.enemy_status_amount or entity.status_amount)
        end
        --Damage
        if entity.enemy_damage_amount > 0 then
          sol.audio.play_sound("enemy_hurt")
          other:blood_splatter(self, 8)
          other:remove_life(entity.enemy_damage_amount)
        end
    end

  end)
  end)

end
