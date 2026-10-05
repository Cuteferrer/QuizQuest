local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(true)
  entity.shoot_type = entity:get_property("shoot_type") or "timed" --options are trigger or timed
  entity.frequency = entity:get_property"frequency" or 4000
  entity.init_delay = entity:get_property"init_delay" or 0
  --entity.trigger_cooldown = entity:get_property"trigger_cooldown" or 7000
  entity.num_shots = tonumber(entity:get_property"num_shots") or 1 --allows dart shooter to fire multiple times when triggered
  entity.shot_delay = entity:get_property"shot_delay" or 500
  --Projectile properties:
  entity.damage = entity:get_property"damage" or 20
  entity.damage_type = entity:get_property"damage_type" or "physical"
  entity.projectile_speed = entity:get_property"projectile_speed" or 200
  entity.can_damage_enemies = entity:get_property"can_damage_enemies" or true

  --Start shooting if timed:
  if entity.shoot_type == "timed" then
    entity:start_shooting()
  elseif entity.shoot_type == "triggered" then

  end
end


function entity:shoot()
  local sprite = entity:get_sprite()

  local function shoot_once()
    sprite:set_animation("shooting", function()
      sprite:set_animation("stopped")
    end)
    if entity:is_in_same_region(map:get_hero()) then
      entity:make_sound("launch")
    end
    local x, y, z = entity:get_center_position()
    local direction = entity:get_direction()
    local dart = map:create_custom_entity{
      x=x, y=y, layer=z, direction = 0, width = 8, height = 8,
      model = "enemy_projectiles/generic_projectile",
      sprite = "hero_projectiles/dart",
    }
    --Set properties:
    dart.rotational_sprite = true
    dart.damage = entity.damage
    dart.damage_type = entity.damage_type
    dart.speed = entity.projectile_speed
    dart.can_damage_enemies = entity.can_damage_enemies
    dart.ignore_obstacles = true
    --Shoot and handle movement/collision:
    dart:shoot(direction * math.pi / 2)
    sol.timer.start(dart,50,function()
      if not dart:overlaps(entity) and dart:get_movement() then
        dart:get_movement():set_ignore_obstacles(false)
      else
        return true
      end
    end)
  end

  local shots_fired = 0
  sol.timer.start(entity, 0, function()
    shoot_once()
    shots_fired = shots_fired + 1
    if shots_fired < entity.num_shots then
      return entity.shot_delay
    end
  end)
end


function entity:start_shooting()
  sol.timer.start(entity, entity.init_delay, function()
    entity:shoot()
    return entity.frequency
  end)
end

