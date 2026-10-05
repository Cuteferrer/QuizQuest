local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite
local movement

function entity:on_created()
  --entity:set_drawn_in_y_order(true)
  entity:set_can_traverse(true)
  entity:set_can_traverse_ground("wall", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)

  entity.collided_entities = {}

  local function check_collision(entity, other)
    local damage = entity.damage or 1
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
        hero:process_hit({damage = damage, enemy = entity, type = type})
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
