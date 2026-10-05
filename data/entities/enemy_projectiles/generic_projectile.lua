local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite
local movement

--[[Preset projectile types, use with entity:set_projectile_type(type)
"arrow"
"fireball"
"iceball"
lightningball"
"webball"
--]]

--[[Parameters
entity.damage
entity.damage_type
entity.speed
entity.max_distance
entity.ignore_obstacles
entity.rotational_sprite - sprite only faces direction 0, is rotated to face angle of travel
entity.can_damage_enemies
entity.tracking_target --causes projectile to track this entity
entity.tracking_step --how accurately it tracks
entity.hero_collision_callback - function, called when hits the hero. If not defined, it just does damage
entity.obstacle_callback - function, called when hits an obstacle
entity.on_fired - function, will be called when the entity is fired
--]]

function entity:on_created()
  entity.is_projectile = true
  entity:set_drawn_in_y_order(true)
  entity:set_can_traverse("enemy", true)
  entity:set_can_traverse("hero",true)
  entity:set_can_traverse("teletransporter", true)
  entity:set_can_traverse("destination", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)

  --Let projectiles cross barbed wire entities:
  entity.can_traverse_barbed_wire = true
end

function entity:shoot(angle)
  local damage = entity.damage or 1
  local damage_type = entity.damage_type or "physical"
  local non_staggering_damage = entity.non_staggering_damage or false
  local max_distance = entity.max_distance or 700
  local speed = entity.speed or 150
  local distance_damage_reduction_rate = entity.distance_damage_reduction_rate
  local ignore_obstacles = entity.ignore_obstacles or false

  if entity.rotational_sprite then
    entity:get_sprite():set_rotation(angle)
  end

  local m = sol.movement.create"straight"
  m:set_speed(speed)
  m:set_angle(angle)
  m:set_max_distance(max_distance)
  m:set_smooth(false)
  m:set_ignore_obstacles(ignore_obstacles)
  m:start(entity, function() entity:hit_obstacle() end)
  function m:on_obstacle_reached()
    m.on_obstacle_reached = nil
    entity:hit_obstacle()
  end
  function m:on_changed()
    if entity.tracking_target then return end --otherwise, changing angle during flight stops the attack
    entity:hit_obstacle()
  end

  local collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other)
    if collided_entities[other] then return end --can't hit twice
    collided_entities[other] = true
    local other_type = other:get_type()
    --Little determination if the attack can hit the target, based on who created it:
    local can_hit = false
    if not entity.firing_entity then
      can_hit = (other_type == "hero" or (other_type == "enemy" and entity.can_damage_enemies))
    elseif entity.firing_entity == "hero_deflect" then
      can_hit = ( other_type == "enemy" )
    elseif entity.firing_entity.can_target then
      can_hit = entity.firing_entity:can_target(other)
    end

    if (other_type == "hero" or other_type == "enemy") and can_hit and not entity.harmless then
      if other.process_hit then
        other:process_hit({damage = damage, enemy = entity, damage_type = damage_type, non_staggering = non_staggering_damage})
      elseif other_type == "hero" then
        other:start_hurt(enemy, damage)
      end
      if other_type == "hero" and entity.hero_collision_callback then
        entity.hero_collision_callback(other)
      end
      entity:hit_obstacle()
    elseif entity.projectile_type == "bullet" and other.react_to_bullet then
      other:react_to_bullet(entity)
    end
  end)

  --Reduce damage as the projectile goes further
  if distance_damage_reduction_rate then
    local rate_step = 10
    sol.timer.start(entity, rate_step, function()
      entity.damage = entity.damage - (distance_damage_reduction_rate)
      damage = entity.damage
      if damage <= 0 then damage = 1 entity.damage = 1 return false end
      return true
    end)
  end

  --Tracking target
  if entity.tracking_target then
    entity:track_entity(entity.tracking_target, entity.tracking_step)
  end

  --Generic callback when fired to extend functionality:
  if entity.on_fired then
    entity.on_fired(entity)
  end
  
end


function entity:hit_obstacle()
  entity:stop_movement()
  if entity.obstacle_callback then
    entity.obstacle_callback(entity)
  else
    entity:pop_remove()
  end
end


function entity:deflect()
  entity.deflected = true
  sol.audio.play_sound("bullet_deflect")
  entity.damage = (entity.damage or 1) * 2
  --game:add_magic((game:get_value("sword_magic_regen_amount") or 15) * 2)
  --Reset some properties:
  entity:clear_collision_tests()
  entity.can_damage_enemies = true
  entity.firing_entity = "hero_deflect"
  local previous_movement = entity:get_movement()
  entity:stop_movement()
  local deflect_angle
  if previous_movement and previous_movement.get_angle then
    deflect_angle = ((previous_movement:get_angle() + math.pi) % (math.pi * 2))
  else
    deflect_angle = hero:get_angle(entity)
  end
  entity:shoot(deflect_angle)
  --[[
  --Hitstop
  game:set_suspended(true)
  sol.timer.start(game, 40, function()
    game:set_suspended(false)
  end)
  --]]
end


function entity:react_to_solforge_weapon(item)
  if entity.melee_deflect then
    entity:deflect()
  elseif entity.melee_destroy then
    entity:stop_movement()
    entity:pop_remove()
  end
end


function entity:pop_remove()
  entity:clear_collision_tests()
  local pop_sprite = entity:create_sprite("enemies/enemy_killed_projectile")
  entity:remove_sprite()
  pop_sprite:set_animation("killed", function() entity:remove() end)
end



function entity:track_entity(target, step)
  if not target then target = entity:get_map():get_hero() end
  local max_tracking_time = entity.max_tracking_time or 600
  step = step or 6
  local frequency = 40
  local elapsed_time = 0
  sol.timer.start(entity, frequency, function()
    elapsed_time = elapsed_time + frequency
    if elapsed_time >= max_tracking_time then return false end
    if not target or not target:exists() then return false end
    local m = entity:get_movement()
    if m and m:get_speed() > 0 then
      local angle = (m:get_angle())
      local target_angle = (entity:get_angle(target))
      local diff = math.abs(target_angle - angle)
      if diff < math.rad(step) then return true end --don't adjust if we're basically on track
      if target_angle < angle then step = step * -1 end
      if diff > math.pi then
        step = step * -1
      end
      angle = angle + math.rad(step)
      angle = angle % (math.pi * 2)
      entity:get_sprite():set_rotation(angle)
      m:set_angle(angle)
    end
    return true
  end)
end


function entity:set_projectile_type(projectile_type)
  entity.projectile_type = projectile_type
  if projectile_type == "arrow" then
    entity.rotational_sprite = true
    entity.speed = 250
    entity.can_damage_enemies = true
    entity.melee_destroy = true

  elseif projectile_type == "rock" then
    --entity.rotational_sprite = true
    entity.speed = 250
    entity.melee_destroy = true
    entity.melee_deflect = game:get_value("ability_deflect_bullets")

  elseif projectile_type == "bomb" then
    entity.harmless = true
    entity.speed = 180
    entity.max_distance = 100
    entity.obstacle_callback = function()
      sol.timer.start(entity, entity.fuse_length or 400, function()
        local x,y,z = entity:get_position()
        local blast = map:create_explosion({
          x=x, y=y, layer=z, sprite = entity.explosion_sprite,
        })
        blast.hero_damage = entity.damage
        blast.enemy_damage = entity.damage
        entity:pop_remove()
      end)
    end

  elseif projectile_type == "bullet" then
    entity.speed = 300
    entity.rotational_sprite = true
    entity.melee_deflect = game:get_value("ability_deflect_bullets")

  elseif projectile_type == "fireball" then
    entity.speed = 200
    entity.rotational_sprite = true
    entity.obstacle_callback = function()
      local x, y, z = entity:get_position()
      map:create_fire{x=x, y=y, layer=z}
      entity:pop_remove()
    end
    entity.hero_collision_callback = function(hero)
      hero:build_up_status_effect("burn", 35)
    end

  elseif projectile_type == "iceball" then
    entity.rotational_sprite = true
    entity.speed = 200
    entity.obstacle_callback = function()
      local ice_blast = map:create_ice_blast(entity:get_position())
      ice_blast:set_duration(200)
      entity:pop_remove()
    end

  elseif projectile_type == "lightningball" then
    entity.rotational_sprite = true
    entity.speed = 250
    entity.obstacle_callback = function()
      local x,y,z = entity:get_position()
      local blast = map:create_lightning({
        x=x, y=y, layer=z, lightning_type="lightning_zap"
      })
      entity:pop_remove()
    end

  elseif projectile_type == "webball" then
    entity.rotational_sprite = true
    entity.speed = 300
    entity.hero_collision_callback = function()
      hero:start_status_effect("webbed", 3000)
    end

  elseif projectile_type == "scatter_grenade" then
    entity.harmless = true
    entity.speed = 180
    entity.distance_variance = entity.distance_variance or 75
    entity.max_distance = 100 + math.random(entity.distance_variance * -1.2, entity.distance_variance)
    entity.fuse_variance = entity.fuse_variance or 500
    entity.fuse_length = (entity.fuse_length or 1000) + math.random(entity.fuse_variance * -1, entity.fuse_variance)
    entity.obstacle_callback = function()
      sol.timer.start(entity, entity.fuse_length or 400, function()
        local x,y,z = entity:get_position()
        local blast = map:create_explosion({
          x=x, y=y, layer=z, sprite = entity.explosion_sprite or "items/explosion_small",
        })
        blast.hero_damage = entity.damage
        blast.enemy_damage = entity.damage
        entity:pop_remove()
      end)
    end

  elseif projectile_type == "bone" then
    entity.speed = 200
    entity.rotational_sprite = false
    entity.melee_deflect = game:get_value("ability_deflect_bullets")
    entity.obstacle_callback = function()
      sol.audio.play_sound("breaking_stone")
      entity:pop_remove()
    end

  end
end

