--[[
Created by Max Mraz, licensed MIT

An entity such as a sawblade, big rolling boulder, swinging axe, etc, which moves and can damage the hero (and/or enemies)
Trigger these entities with either
- a switch with the property: "tripwire_hazard" and value: {hazard entity name}
- a moving_hazard_tripwire entity

Functions you can call to set behavior:
entity:set_flying(true/false) - determines movement over water, holes, etc
entity:set_firing_entity(entity) - sets a "firing entity", who cannot be hurt by the hazard


Entity properties - can set as property values on the map entity:
damage (int)(default 20)
stop_on_damaging (boolean)
rotational_sprite (boolean)
directional_sprite (boolean)
collision_type (string)
repeat_movement (boolean)
repeat_delay (number)
auto_start (boolean or number) - will automatically start moving in the direction of the entity when created - or after a delay if a number is set here. Combine with repeat movement in order to get a back and forth type entity


Properties you can set to determine behavior:
entity.collision_type (string)- sets collision type. Default "sprite", but you might want to change it to "overlapping" for taller entities like upright sawblades or something
entity.harmless_to_hero (boolean) - determines whether or not it'll hurt the hero
entity.harmless_to_enemies (boolean) - determines whether or not it'll hurt enemies
entity.hero_collision_callback (function) - function to overwrite what happens when this hits the hero. Passes the hazard entity and the hero as params
entity.stop_on_damaging (boolean) - if true, the entity will treat entities it hits (hero or enemies) as obstacles and stop when it hits them
entity.distance_damage_reduction_rate (number) - every 10ms while moving, damage is reduced by this amount
entity.rotational_sprite (boolean) - if true, the entity's sprite will rotate in the direction of its movement
entity.directional_sprite (boolean) - if true, the entity's sprite will be set in the direction4 of its movement
entity.melee_deflect (boolean) - if true, hitting it with a melee weapon will deflect the hazard and send it back
entity.melee_destroy (boolean) - if true, hitting it with a melee weapon will destroy the hazaard

--Movement Properties:
entity.speed (default 150)
entity.max_distance (default 700)
entity.repeat_movement (boolean) - if true, when the entity hits an obstacle (or max distance), it will turn around and go back the way it came
entity.repeat_delay (number) how long after hitting an obstacle before turning around and going back

--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite
local movement


function entity:on_created()
  entity.creation_sprite_id = entity:get_sprite():get_animation_set()
  entity:set_drawn_in_y_order(true)
  entity:set_can_traverse("enemy", true)

  entity.damage = tonumber(entity:get_property("damage")) or 20
  entity.stop_on_damaging = (entity:get_property("stop_on_damaging"))
  entity.directional_sprite = (entity:get_property("directional_sprite"))
  entity.rotational_sprite = (entity:get_property("rotational_sprite"))
  entity.collision_type = entity:get_property("collision_type")
  entity.speed = tonumber(entity:get_property"speed" or 150)
  entity.max_distance = tonumber(entity:get_property"max_distance" or 700)
  entity.repeat_movement = (entity:get_property("repeat_movement"))
  entity.repeat_delay = tonumber(entity:get_property("repeat_delay"))
  entity.harmless_to_enemies = (entity:get_property("harmless_to_enemies"))

  local auto_start = entity:get_property"auto_start"
  if auto_start then
    if auto_start == "true" then auto_start = 0 end
    auto_start = tonumber(auto_start)
    sol.timer.start(entity, auto_start, function()
      entity:go(entity:get_direction() * math.pi / 2)
    end)
  end

  if entity:get_property("flying") == "true" then
    entity:set_can_traverse_ground("hole", true)
    entity:set_can_traverse_ground("deep_water", true)
    entity:set_can_traverse_ground("lava", true)
  end

  --Save properties to recreate when checkpoint is rested at:
  local x, y, z = entity:get_position()
  local width, height = entity:get_size()
  local direction = entity:get_direction()
  local name = entity:get_name()
  local sprite_name = entity.creation_sprite_id
  local props = {}
  for _, prop in pairs(entity:get_properties()) do
    local property = {key = prop.key, value = prop.value}
    table.insert(props, property)
  end
  --Checkpoint callback:
  map:register_checkpoint_callback(entity, function(entity)
    if not entity.activated then return end
    entity:remove()
    map:unregister_checkpoint_callback(entity)
    local new_hazard = map:create_custom_entity({
      x=x, y=y, layer=z, width = width, height = height, direction = direction,
      name = name,
      sprite = sprite_name,
      model = entity:get_model(),
      properties = props,
    })
  end)
end


function entity:set_flying(flying)
  assert(type(flying) == "boolean", "entity:set_flying(boolean) must be true or false")
  entity:set_can_traverse_ground("deep_water", flying)
  entity:set_can_traverse_ground("shallow_water", flying)
  entity:set_can_traverse_ground("hole", flying)
  entity:set_can_traverse_ground("lava", flying)
  entity:set_can_traverse_ground("low_wall", flying)
end


function entity:set_firing_entity(other)
  entity.firing_entity = other
end

function entity:get_firing_entity()
  return entity.firing_entity
end


function entity:activate_collision()
  local damage = entity.damage or 20
  local damage_type = entity.damage_type or "physical"

  entity:add_collision_test(entity.collision_type or "sprite", function(entity, other)
    local entity_type = other:get_type()
    if entity:get_firing_entity() == other then return end

    --Hero collision:
    if entity_type == "hero" and hero:get_can_be_hurt() then
      if entity.harmless_to_hero then return end
      if entity.hero_collision_callback then
        entity.hero_collision_callback(entity, hero)
      elseif hero.process_hit then
        hero:process_hit({damage = damage, enemy = entity, damage_type = damage_type})
      else
        hero:start_hurt(entity, damage)
      end
    --Enemy collision
    elseif (entity_type == "enemy") and not entity.harmless_to_enemies then
      if other.process_hit then
        other:process_hit({damage = damage, damage_type = damage_type})
      else
        other:hurt(damage)
      end
    --Custom entity collision
    --Breakable objects
    elseif (entity_type == "custom_entity") and other:get_model() == "world_objects/breakable_object" then
      other:destroy()
    end

    if (entity_type == "hero") or (entity_type == "enemy") then
      --If targets are obstacles, stop
      if entity.stop_on_damaging then
        entity:clear_collision_tests()
        entity:hit_obstacle()
      end
    end

  end)
end



function entity:go(angle)
  local sprite = entity:get_sprite()
  if sprite:has_animation"activated" then sprite:set_animation"activated" end
  entity.activated = true
  --Activate collision once we start going:
  entity:activate_collision()

  local max_distance = entity.max_distance or 700
  local speed = entity.speed or 150
  local distance_damage_reduction_rate = entity.distance_damage_reduction_rate

  if entity.rotational_sprite then
    entity:get_sprite():set_rotation(angle)
  elseif entity.directional_sprite then
    entity:get_sprite():set_direction(sol.main.get_direction4(angle))
  end

  local m = sol.movement.create"straight"
  m:set_speed(speed)
  m:set_angle(angle)
  m:set_max_distance(max_distance)
  m:set_smooth(false)
  m:start(entity, function() entity:hit_obstacle() end)
  function m:on_obstacle_reached()
    m:stop()
    entity:hit_obstacle()
  end
  function m:on_changed()
    entity:hit_obstacle()
  end

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
  
end


function entity:hit_obstacle()
  local m = entity:get_movement()
  local original_angle = m and m:get_angle()
  entity:stop_movement()
  if entity.obstacle_callback then
    entity.obstacle_callback()
  elseif entity.repeat_movement and original_angle then
    sol.timer.start(entity, entity.repeat_delay or 0, function()
      entity:go((original_angle + math.pi) % (2 * math.pi)) --turn around
    end)
  else
    entity:pop_remove()
  end
end


function entity:deflect()
  --[[
  entity.deflected = true
  sol.audio.play_sound("bullet_deflect")
  entity.can_damage_enemies = true
  entity.damage = (entity.damage or 1) * 4
  entity.firing_entity = nil
  entity:stop_movement()
  entity:shoot(hero:get_angle(entity))
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
  local pop_sprite = entity:create_sprite("enemies/enemy_killed")
  entity:remove_sprite()
  sol.audio.play_sound("breaking_crate") --TODO: parameterize this
  pop_sprite:set_animation("killed", function() entity:remove() end)
end

