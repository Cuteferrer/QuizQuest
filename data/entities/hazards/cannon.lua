local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local range = 272
local angle_deviance = 20
local fire_cooldown = 5000
local fuse_duration = 1000
local base_damage = 60


function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  --overrides:
  base_damage = tonumber(entity:get_property("damage")) or base_damage
  range = tonumber(entity:get_property"range") or range

  sol.timer.start(entity, 20, function()
    entity:pair_close_enemy()
  end)
end


function entity:is_paired_to_enemy()
  local paired = false
  if (entity.paired_enemy and entity.paired_enemy:exists()) then
    paired = true
  end
  return paired
end


function entity:on_interaction()
  entity:fire()
end


function entity:activate()
  local hero = map:get_hero()
  entity.fire_timer = sol.timer.start(entity, 500, function()
    if not entity:is_paired_to_enemy() then
      entity:deactivate()
      return
    end
    --Check for hero
    local facing_angle = entity:get_direction() * (math.pi / 2)
    local hero_angle = entity:get_angle(hero)
    local distance = entity:get_distance(hero)
    if (distance <= range) and math.abs(math.deg(hero_angle) - math.deg(facing_angle)) <= angle_deviance then
      entity:fire(hero_angle)
      return fire_cooldown
    else
      return true
    end
  end)
end


function entity:deactivate()
  entity.paired_enemy = nil
  if entity.fire_timer then
    entity.fire_timer:stop()
  end
end


function entity:fire(angle)
  if entity.fuse_timer and entity.fuse_timer:get_remaining_time() > 0 then return end
  local direction = entity:get_direction()
  angle = angle or direction * (math.pi / 2)
  local sprite = entity:get_sprite()
  sprite:set_animation"sparking"
  sol.audio.play_sound("fuse_short")
  entity.fuse_timer = sol.timer.start(entity, fuse_duration, function()
    sprite:set_animation"stopped"
    sol.audio.play_sound"gunshot_cannon"
    local flash_sprite = entity:create_sprite("hazards/cannon")
    flash_sprite:set_direction(direction)
    flash_sprite:set_animation("flash", function() entity:remove_sprite(flash_sprite) end)
    local x, y, z = entity:get_position()
    x, y = x+ game:dx(16)[direction], y + game:dy(16)[direction]
    local projectile = map:create_custom_entity{
      x=x, y=y, layer=z, direction=0, width=16, height=16,
      model = "enemy_projectiles/generic_projectile",
      sprite = "hero_projectiles/cannonball",
    }
    projectile.damage = base_damage
    projectile.speed = 300
    projectile.can_damage_enemies = true
    projectile.obstacle_callback = function()
      local x,y,z = projectile:get_position()
      local blast = map:create_explosion({
        x=x, y=y, layer=z, sprite = entity.explosion_sprite,
      })
      blast.hero_damage = projectile.damage
      blast.enemy_damage = projectile.damage
      projectile:pop_remove()
    end
    projectile:shoot(angle)
  end)

end


function entity:pair_close_enemy()
  local x, y, z = entity:get_position()
  local w, h = 32, 32
  for e in map:get_entities_in_rectangle(x - w, y - h, w * 2, h * 2) do
    if e:get_type() == "enemy" then
      sol.timer.start(entity, 20, function()
        entity:pair_enemy(e)
      end)
      break
    end
  end
end


function entity:pair_enemy(enemy)
  local x, y, z = entity:get_position()
  local direction = entity:get_direction()
  local hero = map:get_hero()
  enemy:set_position(x - game:dx(16)[direction], y - game:dy(16)[direction], z)
  enemy:get_sprite():set_direction(enemy:get_facing_direction_to(entity))
  entity.paired_enemy = enemy

  local old_check_for_hero = enemy.check_for_hero
  enemy.check_for_hero = function()
    --if enemy can see hero:
    if (enemy:get_distance(hero) <= 56) and enemy:has_los(hero) then
      --Check if hero is being stealthy
      if hero.stealth_mode then
        enemy:check_for_stealth_hero()
      else
        enemy.check_for_hero = old_check_for_hero
        enemy:start_aggro()
        entity:deactivate() --deactivate cannon
      end
    --if enemy can't see hero, but the hero is super close
    elseif (enemy:get_distance(hero) <= 32) then
      sol.timer.start(enemy, 500, function()
        enemy.check_for_hero = old_check_for_hero
        enemy:start_aggro()
        entity:deactivate() --deactivate cannon
      end)
    end
  end
  if enemy:exists() then enemy:restart() end

  --Start checking for hero
  entity:activate()
end

