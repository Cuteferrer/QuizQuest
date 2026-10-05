local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local sprite = enemy:get_sprite()

  function enemy:spoke_bullet_attack(props)
    props = props or {}
    local num_projectiles = props.num_projectiles or 6
    local projectile_model = props.projectile_model or "enemy_projectiles/generic_projectile"
    local projectile_sprite = props.projectile_sprite or "entities/enemy_projectiles/generic_projectile"
    local projectile_speed = props.projectile_speed or 150
    local max_distance = props.max_distance or 700
    local rotational_sprite = props.rotational_sprite or false
    local width, height = enemy:get_size()
    local offset = math.max(width, height) + 8
    local x, y, z = enemy:get_position()
    for i = 1, num_projectiles do
      local angle = math.pi * 2 / num_projectiles * (i - 1)
      local projectile = map:create_custom_entity{
        x = x + offset * math.cos(angle),
        y = y + offset * math.sin(angle) * -1,
        layer = z,
        width = 8, height = 8, direction = 0,
        model = projectile_model, sprite = projectile_sprite,
      }
      projectile.max_distance = max_distance
      projectile.speed = projectile_speed
      projectile.rotational_sprite = rotational_sprite
      projectile:shoot(angle)
    end
  end

end

return manager
