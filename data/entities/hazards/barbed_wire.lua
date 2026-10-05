local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local damage = 5
local damage_cooldown = 1000

function entity:on_created()
  entity:set_tiled(true)
  entity.damage = damage
  entity:set_traversable_by(function(entity, other)
    local can_traverse = other.can_traverse_barbed_wire
    if other:get_type() == "custom_entity" and other:get_model() == "world_objects/moving_platform" then can_traverse = true end
    return can_traverse
  end)

  local collided_entities = {}
  entity:add_collision_test("facing", function(entity, other)
    if other:get_type() == "hero" and not collided_entities[other] then
      local state, state_ob = other:get_state()
      if (state_ob and (state_ob:get_description() == "dashing" or state_ob:get_description() == "dash_recovery")) and not other:overlaps(entity, "facing") then
        return
      end
      collided_entities[other] = true
      sol.timer.start(entity, damage_cooldown, function() collided_entities[other] = nil end)
      if other.process_hit then
        other:process_hit{
          damage = entity.damage,
        }
      else
        other:start_hurt(entity, entity.damage)
      end
    end
  end)
end
