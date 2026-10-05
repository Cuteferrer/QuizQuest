--[[
Created by Max Mraz, licensed MIT
Create a custom entity and use this script as its model. Must have three animations:
- "windup"
- "attack"
- "recovery"

properties to set:
entity.damage
entity.drawn_in_y_order
entity.must_overlap --whether sprite collision triggers damage, or need to overlap
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_drawn_in_y_order(entity.drawn_in_y_order or false)
  local sprite = entity:get_sprite()
  sprite:set_animation("windup", function()
    entity:attack()
  end)
  entity.collision_frequency = 600
end


function entity:attack()
  local sprite = entity:get_sprite()
  sprite:set_animation("attack", function()
    entity:recovery()
  end)

  entity.collided_entities = {}
  local function check_collision(entity, other)
    local damage = entity.damage or 1
    local damage_type = entity.damage_type or "physical"
    if entity.collided_entities[other] then return end
    if entity.firing_entity == other then return end --prevent projectiles from hitting the shooter
    entity.collided_entities[other] = other
    sol.timer.start(entity, entity.collision_frequency, function()
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

  if not entity.must_overlap then
    entity:add_collision_test("sprite", function(entity, other)
      check_collision(entity, other)
    end)
  end

  entity:add_collision_test("touching", function(entity, other)
    check_collision(entity, other)
  end)

  entity:add_collision_test("overlapping", function(entity, other)
    check_collision(entity, other)
  end)
end


function entity:recovery()
  entity:clear_collision_tests()
  local sprite = entity:get_sprite()
  sprite:set_animation("recovery", function()
    entity:remove()
  end)
end
