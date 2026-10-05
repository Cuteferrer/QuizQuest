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
  entity:set_can_traverse("custom_entity", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
end

function entity:shoot(angle)
  local damage = entity.damage or 1
  local damage_type = entity.damage_type or "physical"
  local sprite = entity:get_sprite()
  local ignore_obstacles = entity.ignore_obstacles or false
  --sprite:set_transformation_origin(0, -1)
  --sprite:set_xy(0, -14)
  if not entity.non_rotational then
    sprite:set_rotation(angle)
  end
  local m = sol.movement.create"straight"
  m:set_speed(entity.speed or 300)
  m:set_angle(angle)
  m:set_max_distance(entity.range or 700)
  m:set_smooth(false)
  if ignore_obstacles then
    m:set_ignore_obstacles(true)
  end
  m:start(entity, function()
    entity:hit_obstacle()
  end)
  function m:on_obstacle_reached()
    m:stop()
    entity:hit_obstacle()
  end
  function m:on_changed()
    --entity:hit_obstacle() --can't remember why I forced an obstacle collison whenever the movement was changed, but this is incompatible with tracking enemies
  end

  entity:activate_collision()

  --Create a maximum lifespan:
  sol.timer.start(entity, entity.max_lifespan or 5000, function()
    entity:hit_obstacle()
  end)
end


function entity:hit_obstacle(other_entity)
  if entity.obstacle_callback then
    entity:obstacle_callback(other_entity)
  else
    entity:stop_movement()
    local pop_sprite = entity:create_sprite("hero_projectiles/pop")
    entity:remove_sprite()
    pop_sprite:set_animation("killed", function() entity:remove() end)
  end
end


function entity:activate_collision()
  local damage = entity.damage or 1
  local damage_type = entity.damage_type or "physical"
  local sprite = entity:get_sprite()
  local ignore_obstacles = entity.ignore_obstacles
  local is_piercing = entity.is_piercing

  entity.collided_entities = {}
  function process_collision(entity, other)
    if entity.collided_entities[other] then return end
    entity.collided_entities[other] = true
    if other:get_type() == "enemy" and (other:get_life() > 0) and other:is_visible() then
      if other.faction == "hero" then return end --ignore allies
      if (not ignore_obstacles) or (not is_piercing) then
        entity:clear_collision_tests()
      end
      if other.process_hit then
        other:process_hit({damage = damage, damage_type = entity.damage_type})
      else
        other:hurt(damage)
      end
      if (not ignore_obstacles) or (not is_piercing) then
        entity:hit_obstacle(other)
      end
      if entity.on_hit_enemy then --allow projectiles to define extra behavior when they hit enemies
        entity:on_hit_enemy(enemy)
      end
    elseif other:get_type() == "switch" and not other:is_walkable() then
      entity:clear_collision_tests()
      entity:hit_obstacle(other)
      other:toggle()
    elseif other.react_to_hero_projectile then
      other:react_to_hero_projectile()
    end
  end

  entity:add_collision_test("sprite", function(entity, other)
    process_collision(entity, other)
  end)
  entity:add_collision_test("touching", function(entity, other)
    process_collision(entity, other)
  end)
end


--Will cause the projectile to arc toward enemies, even as they move
--Set entity.tracking_accuracy to increase or decrease lock-on amount, default 3
function entity:track_target(target)
  sol.timer.start(entity, 20, function()
    if (not target) or (not target:is_enabled()) or (not target:exists()) or (target:get_life() <= 0) then return end
    local m = entity:get_movement()
    if m and m:get_speed() > 0 then
      local angle = (m:get_angle())
      local target_angle = (entity:get_angle(target:get_center_position()))
      local step = entity.tracking_accuracy or 3
      if target_angle < angle then step = step * -1 end
      local diff = math.abs(target_angle - angle)
      if diff > math.rad(180) then
        step = step * -1
      end
      if diff < math.rad(step) then step = 0 end
      angle = angle + math.rad(step)
      if not entity.non_rotational then entity:get_sprite():set_rotation(angle) end
      m:set_angle(angle)
    end
    return true
  end)
end

--Activates seeking mode, will lock onto the first enemy that comes into range
function entity:start_seeking(range)
  range = range or 60
  sol.timer.start(entity, 20, function()
    local x, y, z = entity:get_position()
    local enemies = {}
    for ent in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
      local dist = ent:get_distance(entity)
      if ent:get_type() == "enemy" and dist <= range and ent.faction ~= "hero" then
        enemies[dist] = ent
      end
    end
    --track closest enemy:
    local closest_enemy, closest_dist
    for dist, enemy in pairs(enemies) do
      if (closest_dist == nil) or (dist < closest_dist) then
        closest_enemy = enemy
        closest_dist = dist
      end
    end
    --repeat
    if closest_enemy then
      entity:track_target(closest_enemy)
      return 500 --don't repeat timer as quickly if a target is acquired
    else
      return true
    end
  end)
end


function entity:set_type(projectile_type)
  if projectile_type == "arrow" then

  elseif projectile_type == "fireball" then
    entity.obstacle_callback = function()
      local x, y, z = entity:get_position()
      local flame = map:create_fire{x=x, y=y, layer=z}
      flame.harmless_to_hero = true
      flame.burn_frequency = 1000
      entity:remove()
    end
  end
end

