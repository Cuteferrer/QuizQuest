--Bullet Spiral Attack:
local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:get_sprite()


function enemy:bullet_spiral_attack(props)
  props = props or {}
  local windup_duration = props.windup_duration or 400
  local windup_animation = props.windup_animation or "stopped"
  local windup_sound = props.windup_sound or "spells/spell_charge"
  local attack_animation = props.attack_animation
  local damage = props.damage or ((enemy.base_damage or 2) / 2)
  local damage_type = props.damage_type or "magic"
  local projectile_sprite = props.projectile_sprite or "entities/enemy_projectiles/silver_orb"
  local projectile_sound = props.projectile_sound or "spells/arcane_bolt"
  local num_projectiles = props.num_projectiles or 24
  local num_rounds = props.num_rounds or 2
  local projectile_offset = props.projectile_offset or 16
  local rotational_sprite = props.rotational_projectile_sprite or true
  local projectile_delay = props.projectile_delay or 80
  local recovery_animation = props.recovery_animation
  local recovery_duration = props.recovery_duration or 400

  local sprite = enemy:get_sprite()
  sprite:set_animation(windup_animation)
  if windup_sound then
    sol.audio.play_sound(windup_sound)
  end

  --Create projectiles while windup goes on:
  local projectiles = {}
  local i = 0
  sol.timer.start(enemy, (windup_duration / num_projectiles), function()
    i = i + 1
    local x, y, z = enemy:get_position()
    local angle = (math.pi * 2 / (num_projectiles / num_rounds)) * i
    local dx, dy = math.cos(angle) * projectile_offset, math.sin(angle) * projectile_offset * -1
    local projectile = map:create_custom_entity{
      x = x + dx, y = y + dy, layer = z,
      width = 16, height = 16, direction = 0,
      model = "enemy_projectiles/generic_projectile",
      sprite = projectile_sprite,
    }
    local projectile_sprite = projectile:get_sprite()
    if rotational_sprite then projectile_sprite:set_rotation(angle) end
    projectile.angle = angle
    projectile:set_visible(false)
    projectiles[i] = projectile
    if #projectiles < num_projectiles then return true end
  end)

  sol.timer.start(enemy, windup_duration, function()
    if attack_animation then
      sprite:set_animation(attack_animation, function()
        sprite:set_animation(recovery_animation and recovery_animation or "stopped")
      end)
    end

    --Fire projectiles:
    local i = 1
    sol.timer.start(enemy, 0, function()
      local projectile = projectiles[i]
      projectile:set_visible(true)
      --Projectile props:
      projectile.damage = damage
      projectile.damage_type = damage_type
      projectile.speed = 120
      projectile:shoot(projectile.angle)
      if projectile_sound then enemy:make_sound(projectile_sound) end
      i = i + 1
      if i < num_projectiles then
        return projectile_delay
      else
        --attack over:
        sol.timer.start(enemy, recovery_duration, function()
          enemy:decide_action()
        end)
      end
    end)

    --failsafe to clear projectiles in case enemy is interrupted:
    sol.timer.start(map, projectile_delay * (num_projectiles + 3) + 10000, function()
      for _, p in ipairs(projectiles) do
        if p:exists() then p:remove() end
      end
      projectiles = nil
    end)
  end)
end



end

return manager
