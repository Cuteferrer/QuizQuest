--[[
By Max Mraz, licensed MIT
Additional functions to be called by the Behavior Applicator script
Adds on useful but optional functions for enemies
For example, some of these are common functions enemies may use in their AI, like retreating, or closing distance before they attack
--]]

local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  --Apply all attacks:
  local attack_scripts = {
    "scripts/modules/trillium/enemies/attacks/beam_attacks",
    "scripts/modules/trillium/enemies/attacks/bullet_spiral_attack",
    "scripts/modules/trillium/enemies/attacks/circle_bursts",
    "scripts/modules/trillium/enemies/attacks/create_circling_projectiles",
    "scripts/modules/trillium/enemies/attacks/explosion_trail",
    "scripts/modules/trillium/enemies/attacks/explosion_burst_attack",
    "scripts/modules/trillium/enemies/attacks/howl",
    "scripts/modules/trillium/enemies/attacks/line_attack",
    "scripts/modules/trillium/enemies/attacks/melee",
    "scripts/modules/trillium/enemies/attacks/misc",
    "scripts/modules/trillium/enemies/attacks/ram_attack",
    "scripts/modules/trillium/enemies/attacks/ranged",
    "scripts/modules/trillium/enemies/attacks/spoke_bullet",
    "scripts/modules/trillium/enemies/attacks/spray_attacks",
    "scripts/modules/trillium/enemies/attacks/vengeful_spirits",
    "scripts/modules/trillium/enemies/attacks/warp_away",
  }
  for _, id in pairs(attack_scripts) do
    require(id).apply_behavior(enemy)
  end


  function enemy:decide_meta_action()
    local handled = false
    --[[ --Okay so this didn't really work, and I thought of a better way to solve the problem it solved anyway.
    local nearby_cannon = enemy:check_to_man_cannon()
    if nearby_cannon then
      nearby_cannon:pair_enemy(enemy)
      return true
    end --]]
    return handled
  end


  function enemy:approach_then_attack(ata_props)
    ata_props = ata_props or {}
    local sprite = enemy:get_sprite()
    local speed = ata_props.speed or 50
    local dist_threshold = ata_props.dist_threshold or 32
    local approach_duration = ata_props.approach_duration or nil
    local animation = ata_props.animation or "walking"
    local target = enemy:choose_target()
    enemy.target_entity = target
    local m = sol.movement.create"target"
    m:set_target(target)
    m:set_speed(speed)
    m:start(enemy)
    sprite:set_animation(animation)
    local elapsed_time = 0
    sol.timer.start(enemy, 50, function()
      elapsed_time = elapsed_time + 50
      if enemy:get_distance(target) <= dist_threshold then
        enemy:stop_movement()
        ata_props.attack_function()
      elseif approach_duration and (elapsed_time >= approach_duration) then
        --Give up the chase:
        enemy.target_entity = nil
        enemy:stop_movement()
        enemy:restart()
      else
        return true
      end
    end)

    function m:on_changed()
      local dir_target = enemy:get_facing_direction_to(target)
      if (target and target:exists()) and (sprite:get_direction() ~= dir_target) then sprite:set_direction(dir_target) end
    end
  end


  function enemy:approach_hero(ata_props)
    ata_props = ata_props or {}
    local sprite = enemy:get_sprite()
    local animation = ata_props.animation or "walking"
    local speed = ata_props.speed or 50
    local dist_threshold = ata_props.dist_threshold or 32
    local approach_duration = ata_props.approach_duration or nil
    local target = enemy:choose_target()
    local callback = ata_props.callback or function() enemy:decide_action() end
    local m = sol.movement.create"target"
    m:set_target(target)
    m:set_speed(speed)
    m:start(enemy)
    sprite:set_animation(animation)
    local elapsed_time = 0
    sol.timer.start(enemy, 50, function()
      elapsed_time = elapsed_time + 50
      if enemy:get_distance(target) <= dist_threshold then
        enemy:stop_movement()
        callback()
      elseif approach_duration and (elapsed_time >= approach_duration) then
        enemy:stop_movement()
        enemy:restart()
      else
        return true
      end
    end)
    function m:on_changed()
      local dir_target = enemy:get_facing_direction_to(target)
      if (target and target:exists()) and (sprite:get_direction() ~= dir_target) then sprite:set_direction(dir_target) end
    end
  end


  function enemy:retreat(attrs)
    local sprite = enemy:get_sprite()
    attrs = attrs or {}
    local speed = attrs.speed or 70
    local duration = attrs.duration or 1000
    local max_distance = attrs.max_distance or 0
    local animation = attrs.animation or "walking"
    local target = enemy:choose_target()
    local angle = attrs.angle or target:get_angle(enemy)
    local lock_facing = attrs.lock_facing or false
    local callback = attrs.callback or function() enemy:decide_action() end
    local test_dist = 8
    local is_blocked = enemy:test_obstacles(test_dist * math.cos(angle), test_dist * math.sin(angle))
    if is_blocked then angle = angle + (math.pi * math.rad(math.random(-45, 45))) end
    local m = sol.movement.create("straight")
    m:set_angle(angle)
    m:set_speed(speed)
    m:set_max_distance(max_distance)
    enemy.lock_facing = lock_facing
    m:start(enemy)
    function m:on_finished()
      sprite:set_animation"stopped"
    end
    function m:on_obstacle_reached()
      m.on_obstacle_reached = nil
      sprite:set_animation"stopped"
    end
    sprite:set_animation(animation)
    sol.timer.start(enemy, duration, function()
      m:stop()
      sprite:set_animation"stopped"
      enemy.lock_facing = false
      callback()
    end)
  end


  function enemy:stagger(length)
    local sprite = enemy:get_sprite()
    length = length or 500
    --ignore stagger if in hyper armor:
    if enemy.hyper_armor then return end
    if enemy.unstaggerable then return end

    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    for _, entity in pairs(enemy.attack_entities) do entity:remove() end
    enemy.aggro = true
    enemy.staggered = true
    if sprite:has_animation("staggered") then
      sprite:set_animation"staggered"
    elseif sprite:has_animation("stunned") then
      sprite:set_animation"stunned"
    elseif sprite:has_animation("stopped") then
      sprite:set_animation"stopped"
    else
      sprite:set_animation"walking"
    end
    sol.timer.start(enemy, length, function()
      enemy.staggered = false
      enemy:restart()
    end)
  end

  function enemy:build_up_stagger(stagger_value)
    enemy:set_stagger_buildup(enemy:get_stagger_buildup() + stagger_value)
    --restart any stagger buildup timer:
    if enemy.stagger_buildup_timer then
      enemy.stagger_buildup_timer:stop()
    end
    --reset stagger buildup after a few seconds
    enemy.stagger_buildup_timer = sol.timer.start(map, 4000, function()
      enemy:set_stagger_buildup(0)
    end)
  end

  function enemy:get_stagger_buildup()
    return enemy.stagger_buildup or 0
  end

  function enemy:set_stagger_buildup(amt)
    enemy.stagger_buildup = amt
  end


  function enemy:should_lose_aggro()
    local should_lose = false
    if not enemy:has_valid_target() then
      return true --lose aggro if no valid target
    end
    local dist = enemy:get_distance(hero)
    if (dist > (enemy.abandon_hero_distance or 200)) or (not enemy:is_in_same_region(hero)) or (enemy:get_layer() ~= hero:get_layer()) then
      should_lose = true
    end
    return should_lose
  end


  --Show a little slash/spark animation on hits:
  function enemy:show_hit_flash(config)
    if enemy:get_life() <= 0 then return end
    config = config or {}
    local color_mod = config.color_modulation or {255,200, 100} 
    local scale = config.scale or 1
    local sprite_id = config.sprite_id or "effects/hit_slash_flash"
    local w, h = enemy:get_size()
    local sprite = enemy:create_sprite(sprite_id)
    sprite:set_animation("flash", function()
      enemy:remove_sprite(sprite)
    end)
    sprite:set_direction(math.random(0, sprite:get_num_directions() - 1))
    sprite:set_xy(0, h * -1 * (math.random(30,80) / 100))
    sprite:set_scale(scale, scale)
    sprite:set_rotation(math.rad(math.random(0, 360)))
    sprite:set_color_modulation(color_mod)
    enemy:bring_sprite_to_front(sprite)
  end


  --Enemy Meta Decisions
  --These are potential actions they might choose to do before their unique enemy:decide_action() AI
  function enemy:check_to_man_cannon()
    local x, y, z = enemy:get_position()
    local check_range = 64
    local nearby_cannon = nil
    for e in map:get_entities_in_rectangle(x - check_range, y - check_range, check_range * 2, check_range * 2) do
      if e:get_type() == "custom_entity" and e:get_model() == "hazards/cannon" and not e:is_paired_to_enemy() and (e:get_direction() == e:get_direction4_to(hero)) then
        nearby_cannon = e
      end
    end
    return nearby_cannon
  end


end


return manager
