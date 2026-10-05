--[[
Creates some entities which will swirl around the enemy, and returns a table containing these projectiles
Doesn't do anything with the entities it creates, that's the enemy's job
Projectile entities are created according to props.projectile_props (but there are default values)
NOTE: this means you'll have to iterate through the table and set stuff like damage and damage type
--]]

local manager = {}


function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  function enemy:create_circling_projectiles(props)
    local projectile_props = props.projectile_props or {}
    local num_projectiles = props.num_projectiles or 5
    local radius = props.radius or 32
    local angular_speed = props.angular_speed or 10
    local acceleration, acceleration_limit = props.acceleration or -0.07, props.acceleration_limit or 3
    local drawn_in_y_order = props.drawn_in_y_order or true
    local ignore_obstacles = props.ignore_obstacles or true

    local projectiles = {}
    local x, y, z = enemy:get_position()
    local projectile_config = {
      x=x, y=y, layer=z,
      width = projectile_props.width or 16,
      height = projectile_props.height or 16,
      direction = projectile_props.direction or 0,
      model = projectile_props.model or "enemy_projectiles/general_attack",
      sprite = projectile_props.sprite or "entities/enemy_projectiles/generic_projectile"
    }
    for i = 1, num_projectiles do
      local angle = (math.pi * 2 / num_projectiles) * i
      local projectile = map:create_custom_entity(projectile_config)
      projectile:set_can_traverse("custom_entity", true)
      projectile:set_drawn_in_y_order(drawn_in_y_order)
      table.insert(enemy.attack_entities, projectile) --NOTE: idk if you want this or not, but you probably want these attacks to go away when the enemy dies
      local m = sol.movement.create"circle"
      m:set_center(enemy, 0, -16)
      --m:set_ignore_obstacles(true) --Note: again, idk
      m:set_radius(0)
      m:set_radius_speed(120)
      m:set_angle_from_center(angle)
      m:set_angular_speed(angular_speed)
      m:set_acceleration(projectile, acceleration, acceleration_limit)
      m:set_ignore_obstacles(ignore_obstacles)

      m:start(projectile)
      m:set_radius(radius)
      projectiles[i] = projectile
    end
    return projectiles

  end

end


return manager
