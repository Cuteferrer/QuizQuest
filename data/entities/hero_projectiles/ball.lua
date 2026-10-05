local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite
local movement


function entity:on_created()
  entity.is_projectile = true
  entity:set_drawn_in_y_order(true)
  entity:set_can_traverse(true)
  entity:set_can_traverse("enemy", true)
  entity:set_can_traverse("hero", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
end

function entity:shoot(angle)
  local damage = entity.damage or 1
  local damage_type = entity.damage_type or "physical"

  local m = sol.movement.create"straight"
  m:set_speed(200)
  m:set_angle(angle)
  m:set_max_distance(700)
  m:set_smooth(false)
  m:start(entity, function() entity:hit_obstacle() end)
  function m:on_obstacle_reached()
    entity:hit_obstacle()
  end
  function m:on_changed()
    entity:hit_obstacle()
  end

  function process_collision(entity, other)
    if other:get_type() == "enemy" then
      entity:clear_collision_tests()
      if other.process_hit then
        other:process_hit({damage = damage})
      else
        other:hurt(damage)
      end
      entity:hit_obstacle()
    end
  end

  entity:add_collision_test("sprite", function(entity, other)
    process_collision(entity, other)
  end)
  entity:add_collision_test("touching", function(entity, other)
    process_collision(entity, other)
  end)

end


function entity:hit_obstacle()
  entity:stop_movement()
  local pop_sprite = entity:create_sprite("enemies/enemy_killed_projectile")
  entity:remove_sprite()
  pop_sprite:set_animation("killed", function() entity:remove() end)
end

