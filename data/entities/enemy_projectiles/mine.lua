--[[
Created by Max Mraz, licensed MIT
A mine entity, to be placed by enemies or whatever
Create a custom entity and use this script as its model. Must have a sprite with a default animation, and an "exploding" animation, which must not loop
Then call either:
entity:set_fuse(time) --to explode after {time} amount of time
entity:set_trip() --will explode when touched by the hero (or maybe other enemies)

You can also set some values:
entity.damage (default 1)
entity.explosion_sound (sound when exploding)
entity.triggered_by_enemies (in trip mine mode, enemies can trip it in addition to the hero)
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local movement

function entity:on_created()

end


function entity:set_fuse(time)
  sol.timer.start(entity, time, function()
    entity:explode()
  end)
end


function entity:set_trip()
  local function check_collision(entity, other)
    if other:get_type() == "hero" then
      entity:explode()
    elseif other:get_type() == "enemy" and entity.triggered_by_enemies then
      entity:explode()
    end
  end
  --entity:add_collision_test("sprite", check_collision)
  entity:add_collision_test("overlapping", check_collision)
end


function entity:explode()
  local sprite = entity:get_sprite()
  if sprite:has_animation"exploding" then
    sprite:set_animation("exploding", function()
      entity:remove()
    end)
  end
  sol.audio.play_sound(entity.explosion_sound or "explosion_grenade")

  entity.collided_entities = {}

  local function check_collision(entity, other)
    local damage = entity.damage or 1
    local damage_type = entity.damage_type or "physical"
    if entity.collided_entities[other] then return end
    if entity.firing_entity == other then return end --prevent projectiles from hitting the shooter
    entity.collided_entities[other] = other
    sol.timer.start(entity, 300, function()
      entity.collided_entities[other] = nil
    end)
    if other:get_type() == "hero" and hero:get_can_be_hurt() then
      if entity.hero_collision_callback then
        entity.hero_collision_callback()
      elseif hero.process_hit then
        hero:process_hit({damage = damage, enemy = entity, damage_type = damage_type})
      else
        hero:start_hurt(entity, damage)
      end
    --Some projectiles can also damage other enemies. Because that's fun.
    elseif entity.can_damage_enemies and (other:get_type() == "enemy") and not (entity.firing_entity == other) then
      if other.process_hit then
        other:process_hit({damage = damage})
      else
        other:hurt(damage)
      end
    elseif other.react_to_enemy_projectile then
      other:react_to_enemy_projectile(projectile)
    end
  end

  entity:add_collision_test("sprite", function(entity, other)
    check_collision(entity, other)
  end)

  entity:add_collision_test("touching", function(entity, other)
    check_collision(entity, other)
  end)
end
