local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity.damage = 1
  entity.damage_type = "physical"
end


function entity:enable_collision()
  entity:add_collision_test("sprite", function(entity, other)
    if other:get_type() == "hero" and other:get_can_be_hurt() then
      local damage = entity.damage
      local damage_type = entity.damage_type
      local ragdoll = entity.ragdoll or false
      entity:clear_collision_tests()
      if other.process_hit then
        other:process_hit({damage = damage, enemy = entity, damage_type = damage_type})
      else
        other:start_hurt(enemy, damage)
      end
      if ragdoll then
        other:ragdoll(entity:get_angle(other),64)
      end
    end
  end)
end

