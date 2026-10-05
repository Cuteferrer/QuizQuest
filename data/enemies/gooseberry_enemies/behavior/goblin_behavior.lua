require"enemies/gooseberry_enemies/behavior/line_of_sight"

local manager = {}

function manager:apply(enemy, props)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite

  local life = props.life or 4
  local damage = props.damage or 1
  local has_melee_attack = props.has_melee_attack or false
  local has_ranged_attack = props.has_ranged_attack or false
  local max_distance_from_home = props.max_distance_from_home or 200
  local alert_distance = props.alert_distance or 100
  local unalert_distance = props.unalert_distance or 200
  local alert_nearby_enemies_range = props.alert_nearby_enemies_range or 96
  local attack_distance = props.attack_distance or 48
  local wander_speed = props.wander_speed or 24
  local chase_speed = props.chase_speed or 60
  local attack_sprite = props.attack_sprite or "enemies/gooseberry_enemies/attacks/slash" --sprite of weapon attack
  local attack_animation = props.attack_animation or "attack" --sprite of enemy while attacking
  local attack_sound = props.attack_sound or "sword3"
  local attack_cooldown_length = props. attack_cooldown_length or 2000


  function enemy:on_created()
    sprite = props.sprite or enemy:create_sprite("enemies/" .. enemy:get_breed())
    enemy:set_life(life)
    enemy:set_damage(damage)
    enemy.state = "idle"
    enemy.attack_cooldown = false
    enemy.home_x, enemy.home_y = enemy:get_position()
  end


  function enemy:on_movement_changed(m)
    sprite:set_direction(m:get_direction4())
  end


  function enemy:on_restarted()
    enemy:decide_action()
  end


  function enemy:decide_action()
    --Decides next state based on current and other information
    local state = enemy.state
    local distance = enemy:get_distance(hero)
    if (state == "idle" or state == "wandering") and enemy:can_see_hero(alert_distance) then
      enemy.state = "alerted"
      enemy:alert_nearby_enemies()
      enemy:stop_movement()
      sprite:set_direction(enemy:get_direction4_to(hero))
      sol.timer.start(enemy, 400, function() enemy:decide_action() end)

    elseif state == "alerted" and enemy:get_distance(hero) >= (unalert_distance or alert_distance + 100) then
      enemy.state = "idle"
      enemy:stop_movement()
      sol.timer.start(enemy, 400, function() enemy:decide_action() end)

    elseif state == "alerted" and has_ranged_attack and enemy:has_los(hero) and not enemy.attack_cooldown then
      enemy:shoot()

    elseif state == "alerted" and has_melee_attack and not enemy.attack_cooldown then
      enemy:approach_then_attack()

    elseif state == "alerted" then
      enemy:approach_hero()
      --enemy:wait_a_sec()

    elseif state == "idle" then
      enemy.state = "wandering"
      enemy:wander()

    elseif state == "wandering" then
      if enemy:get_distance(enemy.home_x, enemy.home_y) >= max_distance_from_home then
        enemy:go_home()
      else
        enemy:wander()
      end

    end
  end


  function enemy:approach_then_attack()
    local approach_duration = 1500
    local m = sol.movement.create"target"
    m:set_speed(chase_speed)
    m:start(enemy)
    sprite:set_animation"walking"
    function m:on_changed()
      sprite:set_direction(m:get_direction4())
    end
    local elapsed_time = 0
    sol.timer.start(enemy, 50, function()
      elapsed_time = elapsed_time + 50
      if enemy:get_distance(hero) <= (attack_distance or 48) then
        enemy:attack()
      elseif approach_duration and (elapsed_time >= approach_duration) then
        enemy:stop_movement()
        enemy:restart()
        enemy.state = "alerted"
        enemy:decide_action()
      else
        return true
      end
    end)
  end


  function enemy:approach_hero()
    if enemy:get_distance(hero) >= 24 then
      local x, y = hero:get_position()
      local m = sol.movement.create"target"
      m:set_target(x + math.random(-32, 32), y + math.random(-32, 32) )
      m:set_speed(chase_speed)
      m:start(enemy)
      if not sprite:get_animation() == "walking" then sprite:set_animation"walking" end
      function m:on_changed() sprite:set_direction(m:get_direction4()) end
    else
      enemy:stop_movement()
      sprite:set_direction(enemy:get_direction4_to(hero))
    end
    sol.timer.start(enemy, 500, function() enemy:decide_action() end)
  end


  function enemy:wait_a_sec()
    sprite:set_direction(enemy:get_direction4_to(hero))
    sol.timer.start(enemy, 500, function() enemy:decide_action() end)
  end


  function enemy:wander()
    local movement = sol.movement.create("random_path")
    movement:set_speed(wander_speed)
    function movement:on_changed()
      sprite:set_direction(movement:get_direction4())
    end
    movement:start(enemy)
    sol.timer.start(enemy, 100, function()
      if enemy:can_see_hero() then
        enemy:decide_action()
      else
        return true
      end
    end)
  end


  function enemy:go_home()
    local m = sol.movement.create"target"
    m:set_target(enemy.home_x, enemy.home_y)
    m:set_speed(wander_speed)
    m:start(enemy)
    sol.timer.start(enemy, math.random(1000, 3000), function()
      enemy:wander()
    end)
  end


  function enemy:can_see_hero(distance)
    distance = distance or alert_distance
    local near = enemy:is_in_same_region(hero)
      and enemy:get_distance(hero) <= distance
      and enemy:get_layer() == hero:get_layer()
      and enemy:has_los(hero)
    return near
  end


  function enemy:attack()
    if enemy:get_movement() then enemy:get_movement():set_speed(1) end
    sol.audio.play_sound(attack_sound or "sword1")
    local attack_sprite = enemy:create_sprite(attack_sprite)
    attack_sprite:set_direction(sprite:get_direction())
    sprite:set_animation(attack_animation, function()
      sprite:set_animation"walking"
      enemy:remove_sprite(attack_sprite)
      enemy.state = "alerted"
      enemy:decide_action()
    end)
    enemy.attack_cooldown = true
    sol.timer.start(map, attack_cooldown_length, function() enemy.attack_cooldown = false end)
  end


  function enemy:shoot()
    enemy:get_movement():set_speed(1)
    enemy:shoot_omnidirectional({
      speed = 160,
      breed = "gooseberry_enemies/projectiles/magic_thing"
    })
    sol.timer.start(enemy, 800, function()
      enemy.state = "alerted"
      enemy:decide_action()
    end)
    enemy.attack_cooldown = true
    sol.timer.start(map, attack_cooldown_length, function() enemy.attack_cooldown = false end)
  end


  function enemy:alert_nearby_enemies()
    local x, y, z = enemy:get_position()
    local range = alert_nearby_enemies_range
    for e in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
      if e:get_type() == "enemy" and e:get_breed():match("gobin") and e:get_distance(enemy) <= range
      and (enemy:has_los(e) or e:has_los(hero)) and e.state == "idle" or e.state == "wandering" then
        e.state = "alerted"
        e:decide_action()
      end
    end
  end


  --Get alerted to hero when hurt
  enemy:register_event("on_hurt", function()
    enemy.state = "alerted"
    enemy:alert_nearby_enemies()
  end)

  enemy:register_event("on_immobilized", function()
    sol.timer.stop_all(enemy)
    enemy.state = "idle"
  end)



end

return manager