local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_can_traverse(true)
  --entity:set_can_traverse_ground("wall", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
  map:register_light_source(entity, "explosion")

  entity.hero_damage = entity.hero_damage  or 10
  entity.enemy_damage = entity.enemy_damage  or 10

  local sprite = entity:get_sprite()
  function sprite:on_animation_finished()
    entity:remove()
  end


  local collided_entities = {}
  local function explosion_collision(entity, other)
    local status_effect_type = entity.status_effect_type or "burn"
    if collided_entities[other] then return end
    collided_entities[other] = true

    if other.react_to_explosion then
      other:react_to_explosion(entity)

    elseif other:get_type() == "hero" and not entity.ignore_hero then
      other:start_hurt(entity.hero_damage)
      if entity.hero_status_amount and other.build_up_status_effect then
        other:build_up_status_effect(status_effect_type, entity.hero_status_amount)
      end

    elseif other:get_type() == "enemy" and not entity.explosion_immunity then
      entity.enemy_damage = entity.enemy_damage * (game.explosion_charm_damage_mod or 1)
      if other.process_hit then
        other:process_hit({damage = entity.enemy_damage, damage_type = entity.damage_type, stagger_value = 50})
      else
        other:hurt(entity.enemy_damage)
      end
      if entity.enemy_status_amount and other.build_up_status_effect then
        other:build_up_status_effect(status_effect_type, entity.enemy_status_amount)
      end
      if entity.stagger_duration and other.stagger then
        other:stagger(entity.stagger_duration)
      end

    end
  end

  entity:add_collision_test("sprite", function(entity, other)
    sol.timer.start(entity, 10, function()
      explosion_collision(entity, other)
    end)
    local num_frames = sprite:get_num_frames()
    local frame_delay = sprite:get_frame_delay()
    local collision_duration = math.min(num_frames, 4) * frame_delay
    sol.timer.start(entity, collision_duration, function()
      entity:clear_collision_tests()
    end)
  end)

end
