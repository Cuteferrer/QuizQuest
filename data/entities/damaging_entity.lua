--[[
Created by Max Mraz, licensed MIT
An entity that damages enemies or the hero
. It will last either entity.duration (if you set it), or else though its animation. Then it will be removed.
optional parameters to set are:
entity.damage (how much damage it causes, default 1)
entity.damage_cooldown (cooldown between hurting the same entity another time, default 200ms)
entity.duration (how long the entity lasts)
entity.harmless_to_hero --default true
entity.harmless_to_enemies --default false
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity.harmless_to_hero = entity.harmless_to_hero or true
  entity.harmless_to_enemies = entity.harmless_to_enemies or false
  sol.timer.start(entity, 10, function()
    if not entity.start_without_collision then
      entity:activate_collision()
    end
  end)

  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
end


function entity:activate_collision()
  entity.collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other, entity_sprite, other_sprite)
    if entity_sprite.harmless then return end --for entities with multiple sprites
    --Hurt enemies:
    if other:get_type() == "enemy" and not entity.harmless_to_enemies and not entity.collided_entities[other] then
      entity.collided_entities[other] = other
      sol.timer.start(entity, entity.damage_cooldown or 200, function() entity.collided_entities[other] = nil end)
      if other.process_hit then
        other:process_hit({damage = entity.damage or 1, damage_type = entity.damage_type or "physical"})
      else
        other:hurt(entity.damage or 1)
      end

      if entity.collision_callback then
        entity:collision_callback(other)
      end
    --Hurt hero:
    elseif other:get_type() == "hero" and not entity.harmless_to_hero and not entity.collided_entities[other] then
      entity.collided_entities[other] = other
      sol.timer.start(entity, entity.damage_cooldown or 200, function() entity.collided_entities[other] = nil end)
      if other.process_hit then
        other:process_hit({
          damage = entity.damage or 1,
          damage_type = entity.damage_type or "physical",
        })
      else
        other:hurt(entity.damage or 1)
      end

      if entity.collision_callback then
        entity:collision_callback(other)
      end
    end
  end)

  --determine removal
  sol.timer.start(entity, 10, function() --wait 10ms so the code that created the entity can set a duration
    if entity.duration then
      sol.timer.start(entity, entity.duration, function() entity:remove() end)
    else
      local sprite = entity:get_sprite()
      function sprite:on_animation_finished() entity:remove() end
    end
  end)
end
