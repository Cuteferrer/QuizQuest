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
  entity:set_can_traverse("wall", false)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
end

function entity:shoot(angle)
--
  local damage = game:calculate_hero_output_damage(entity.damage or 50, "guns")
  local damage_type = entity.damage_type or "bullet"
  local sprite = entity:get_sprite()
  local is_piercing = entity.is_piercing or false
  local speed = entity.speed or 300
  if entity.speed_variance then speed = speed + math.random(entity.speed_variance * -1, entity.speed_variance) end
  local range = entity.range or 700
  if entity.range_variance then range = range + math.random(entity.range_variance * -1, entity.range_variance) end
  --sprite:set_transformation_origin(0, -1)
  sprite:set_xy(0, -8)
  if not entity.non_rotational then
    sprite:set_rotation(angle)
  end
  local m = sol.movement.create"straight"
  m:set_speed(speed)
  m:set_angle(angle)
  m:set_max_distance(range)
  m:set_smooth(false)
  if is_piercing then
    m:set_ignore_obstacles(true)
  end
  m:start(entity)

  local function end_movement()
    entity:hit_obstacle()
  end
  m.on_finished = end_movement
  m.on_obstacle_reached = end_movement
  m.on_changed = end_movement

  entity.collided_entities = {}
  function process_collision(entity, other)
    if entity.collided_entities[other] then return end
    entity.collided_entities[other] = true
    if other:get_type() == "enemy" and (other:get_life() > 0) and other:is_visible() then
      if other.faction == "hero" then return end --don't hurt allies
      if not is_piercing then
        entity:clear_collision_tests()
      end
      if other.process_hit then
        other:process_hit({damage = damage, damage_type = damage_type, stagger_value = 0})
      else
        other:hurt(damage)
      end
      if not is_piercing then
        entity:hit_obstacle(other)
      end
      --allow for guns to define behavior on the bullet
      if entity.enemy_collision_callback then entity:enemy_collision_callback(other) end

    elseif other:get_type() == "switch" and not other:is_walkable() then
      entity:clear_collision_tests()
      entity:hit_obstacle()
      other:toggle()
    elseif other.react_to_hero_projectile then
      other:react_to_hero_projectile()
    elseif other.react_to_bullet then
      other:react_to_bullet(entity)
    end
  end

  entity:add_collision_test("sprite", function(entity, other)
    process_collision(entity, other)
  end)
  entity:add_collision_test("touching", function(entity, other)
    process_collision(entity, other)
  end)
--]]

end


function entity:hit_obstacle(other_entity)
  entity:stop_movement()
  local pop_sprite = entity:create_sprite(entity.dying_sprite_id or "hero_projectiles/pop")
  pop_sprite:set_xy(0, -14)
  entity:remove_sprite()
  pop_sprite:set_animation("killed", function() entity:remove() end)
  --allow for guns to define behavior on the bullet
  if entity.obstacle_collision_callback then entity:obstacle_collision_callback(other_entity) end
end

