--[[
By Max Mraz, licensed MIT
--]]

require("scripts/modules/trillium/enemies/lib/line_of_sight")
local node_movement = require("scripts/modules/trillium/enemies/lib/node_movement")
local aux_behavior = require("scripts/modules/trillium/enemies/lib/behavior_functions")
local enemy_stat_config_table = sol.file.exists("enemies/enemy_stat_values.lua") and require("enemies/enemy_stat_values")

local applicator = {}

local enemy_hurt_shader = sol.shader.create("enemy_hurt_2")
local hurt_flash_time = 90 --150 --amount of time for which an enemy flashes when hit
local normal_stagger_length = 300 --amount of time for which an enemy is staggered after taking a hit
local traversable_enemies = true

function applicator:apply_behavior(enemy, props)
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local breed = enemy:get_breed()
  local sprite

  node_movement.apply_behavior(enemy)
  aux_behavior.apply_behavior(enemy)

  --Apply any enemy properties from config file:
  if enemy_stat_config_table and enemy_stat_config_table[breed] then
    for k, v in pairs(enemy_stat_config_table[breed]) do
      enemy[k] = v
    end
  end
  --Scale enemy to map level (this must be done before attacks that use enemy.base_damage are defined, otherwise that value won't update for higher-level maps)
  if enemy.scale_to_area_level then enemy:scale_to_area_level() end

  enemy:register_event("on_created", function()
    sprite = enemy:create_sprite(props.sprite or ("enemies/" .. enemy:get_breed()), "main")
    enemy:set_traversable(traversable_enemies)
    enemy.sprite_direction_style = props.sprite_direction_style or "normal" --can also be "horizontal", "diagonal", or "single"
    enemy.attack_entities = {}
    enemy.max_life = enemy.max_life or props.max_life or props.life or 10
    enemy:set_life(enemy.max_life)
    enemy:set_damage(props.contact_damage or 1)
    enemy.detection_distance = props.detection_distance or 150
    enemy.abandon_hero_distance = props.abandon_hero_distance or 500
    enemy.home_x, enemy.home_y, enemy.home_z = enemy:get_position()
    enemy.idle_movement_speed = props.idle_movement_speed or 20
    enemy.stunlock_counter = 0
    enemy.stunlock_limit = props.stunlock_limit or 8
    enemy.stunlock_reset_rate = props.stunlock_reset_rate or 1500
    enemy.stunlock_reset_amount = props.stunlock_reset_amount or enemy.stunlock_limit / 2
    enemy.ally_alert_range = props.ally_alert_range or 64
    enemy.stagger_when_hurt = props.stagger_when_hurt or false
    enemy.stagger_life_percent = props.stagger_life_percent or 30
    if (props.width or props.height) then
      enemy:set_size(props.width or 16, props.height or 16)
      enemy:set_origin( props.origin_x or ((props.width or 16) / 2), props.origin_y or ((props.height or 16) - 3) )
    end
    enemy:create_traverse_collider()

    enemy.aggro = false
  end)


  --Make enemy face the way it's moving, unless enemy.lock_facing is set
  local previous_direction
  local previous_angle
  function enemy:on_movement_changed(m)
    if not m.get_speed then return end
    if (not enemy.lock_facing) and (m:get_speed() > 0) then
      --local m_angle = m:get_angle() --TODO: current engine bug, can't do this on random movements
      local m_angle = m:get_direction4() * math.pi / 2
      local dir = enemy:get_facing_direction_to(m_angle)
      if (dir ~= previous_direction) and (m_angle ~= previous_angle) then
        --Hardcode some exceptions:
        if (enemy.sprite_direction_style == "horizontal") and (m_angle == (math.pi / 2) or m_angle == (3 * math.pi / 2)) then
          return --don't turn horizontal style enemies when they're perfectly up or down, just let them keep their previous direction
        elseif (enemy.sprite_direction_style == "single") then
          return --don't turn single-direction enemies
        end
        sprite:set_direction(dir)
        previous_direction = dir
        previous_angle = m_angle
      end
    end
  end


  --Create a collider to prevent enemies from overlapping each other and the hero:
  function enemy:create_traverse_collider()
    local enemy_sprite = enemy:get_sprite()
    local x, y, z = enemy:get_position()
    local w, h = props.width or 16, props.height or 16
    local collider = map:create_custom_entity{
      x=x, y=y, layer=z, direction=0,
      width = w, height = h, 
    }
    local ox = props.origin_x or w / 2
    local oy = props.origin_y or h - 3
    collider:set_origin(ox, oy)
    collider.active = true --Can disable when needed
    --[[For testing: give the collider a sprite:
    collider:create_sprite("utility/dot_orange")
    collider:set_tiled(true)
    --]]
    local function can_pass(other)
      if not collider.active then return true end
      if (enemy:is_enabled() == false) then return true end --allow other entity to pass while enemy is disabled
      if other.ignore_enemy_traverse_collider then return true end --allow other entity to bypass collider
      if (enemy:is_visible() == false) or (enemy_sprite:get_opacity() <= 0) then return true end --allow entities to pass if enemy is invisible
      if enemy:get_life() <= 0 then collider:remove() return true end --if enemy is dead, allow to pass and also remove the collider
      return other:overlaps(collider)
    end
    collider:set_traversable_by("enemy", function(collider, other)
      return can_pass(other)
    end)
    collider:set_traversable_by("hero", function(collider, other)
      return can_pass(other)
    end)
    enemy:register_event("on_position_changed", function(enemy, x, y, z)
      collider:set_position(x, y, z)
    end)
    enemy:register_event("on_removed", function()
      collider:remove()
    end)
    enemy.traverse_collider = collider
  end


  enemy:register_event("on_position_changed", function()
    --Set traversable if the hero overlaps, otherwise defer to config
    if enemy:overlaps(hero) then
      enemy:set_traversable(true)
    else
      enemy:set_traversable(traversable_enemies)
    end
  end)


  enemy:register_event("on_restarted", function()
    if game.prevent_enemy_aggro then return end
    for _, entity in pairs(enemy.attack_entities) do entity:remove() end
    enemy.attack_entities = {}
    enemy:set_can_attack(props.contact_damage and true or false)
    enemy.hyper_armor = nil --remove any hyper armor
    if not enemy.aggro then
      enemy:start_idle()
    elseif (enemy.stunlock_counter >= enemy.stunlock_limit) and enemy.stunlock_break then
      enemy.stunlock_counter = math.max(enemy.stunlock_counter - enemy.stunlock_reset_amount, 0)
      enemy:stunlock_break()
    else
      enemy:stop_movement()
      local meta_action_chosen = enemy.decide_meta_action and enemy:decide_meta_action() or false
      if not meta_action_chosen then
        enemy:decide_action()
      end
    end
    sol.timer.start(enemy, enemy.stunlock_reset_rate, function()
      enemy.stunlock_counter = math.max(enemy.stunlock_counter - enemy.stunlock_reset_amount, 0)
      return true
    end)
  end)


  enemy:register_event("on_hurt", function()
    --for _, entity in pairs(enemy.attack_entities) do entity:remove() end --moved to stagger function
    enemy.aggro = true
    enemy:alert_nearby_enemies()
    enemy.stunlock_counter = enemy.stunlock_counter + 1
  end)


  function enemy:start_idle()
    enemy.aggro = false
    local idle_movement_type = enemy:get_property("idle_movement_type")
    if idle_movement_type and ((idle_movement_type == "walk") or (idle_movement_type == "walking") or (idle_movement_type == "random")) then
      sprite:set_animation"walking"
      if idle_movement_type == "random" and enemy.move_randomly then
        enemy:move_randomly()
      else
        local m
        if (idle_movement_type == "random") then
          m = sol.movement.create"random"
        else
          m = sol.movement.create"random_path"
        end
        m:set_speed(enemy.idle_movement_speed)
        m:start(enemy)
        function m:on_changed()
          if enemy:get_distance(enemy.home_x, enemy.home_y) >= 100 then
            m = sol.movement.create"target"
            m:set_target(enemy.home_x, enemy.home_y)
            m:set_speed(enemy.idle_movement_speed)
            m:start(enemy)
            sol.timer.start(enemy, 3000, function() enemy:start_idle() end)
          end
        end
      end

    elseif idle_movement_type and (idle_movement_type == "node") then
      sprite:set_animation"walking"
      enemy:start_node_movement()

    else
      if sprite:has_animation"idle" then sprite:set_animation"idle"
      elseif sprite:has_animation"stopped" then sprite:set_animation"stopped"
      elseif sprite:has_animation"walking" then sprite:set_animation"walking" end
    end
    local check_freq = 100
    sol.timer.start(enemy, math.random(1, check_freq), function()
      enemy:check_for_hero()
      return check_freq
    end)
  end


  function enemy:check_for_hero()
    local is_on_screen = not enemy.is_on_screen or enemy:is_on_screen()
    --if enemy can see hero:
    if (enemy.aggro) or ((enemy:get_distance(hero) <= enemy.detection_distance) and enemy:has_los(hero) and is_on_screen) then
      --Check if hero is being stealthy
      if hero.stealth_mode then
        enemy:check_for_stealth_hero()
      else
        enemy:start_aggro()
      end
    --if enemy can't see hero, but the hero is super close
    elseif (enemy:get_distance(hero) <= 32) then
      sol.timer.start(enemy, 500, function() enemy.aggro = true end)
    end
  end


  function enemy:check_for_stealth_hero()
    local speed = hero:get_movement():get_speed()
    if speed > 0 then
      sol.timer.stop_all(enemy)
      enemy:stop_movement()
      if sprite:has_animation"stopped" then sprite:set_animation"stopped" end
      local alert_sprite = enemy:create_sprite("enemies/alert_meter")
      local _, height = sprite:get_size()
      alert_sprite:set_xy(0, height * -1 )
      sol.audio.play_sound"key_fall"
      enemy:get_sprite():set_direction(enemy:get_facing_direction_to(hero))
      if not enemy.hero_alert_points then enemy.hero_alert_points = 0 end
      enemy.hero_alert_points = enemy.hero_alert_points + 15
      sol.timer.start(enemy, 20, function()
        if hero:get_movement():get_speed() > 0 then
          enemy.hero_alert_points = enemy.hero_alert_points + 10
        else
          enemy.hero_alert_points = enemy.hero_alert_points - 2
        end
        if enemy.hero_alert_points <= 0 then
          enemy:remove_sprite(alert_sprite)
          sol.timer.start(enemy, 300, function() enemy:start_idle() end)
        elseif enemy.hero_alert_points >= 150 then
          enemy.hero_alert_points = 0
          enemy:remove_sprite(alert_sprite)
          enemy:start_aggro()
        else
          return true
        end
      end)
    end
  end


  function enemy:start_aggro()
    enemy.aggro = true
    --enemy:alert_nearby_enemies() --this should just happen in on_hurt, not any aggro
    sol.timer.stop_all(enemy)
    enemy:restart()
  end


  function enemy:return_to_idle()
    enemy.aggro = false
    enemy:restart()
  end


  function enemy:alert_nearby_enemies()
    local range = enemy.ally_alert_range
    local x,y,z = enemy:get_position()
    for entity in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
      if entity:get_type() == "enemy" and (enemy:get_distance(entity) <= range) then
        entity.aggro = true
      end
    end
  end


  function enemy:is_aligned(entity, threshold)
    threshold = threshold or 16
    local is_aligned = false
    local x,y = enemy:get_position()
    local ex, ey = entity:get_position()
    if (math.abs(x - ex) <= threshold) or (math.abs(y - ey) <= threshold) then
      is_aligned = true
    end
    return is_aligned
  end


  function enemy:get_facing_direction_to(target)
    --If a number was passed as argument (then the target is an angle)
    if type(target) == "number" then
      local angle = target
      if enemy.sprite_direction_style == "diagonal" then
        return math.floor(angle / (math.pi / 2))
      elseif enemy.sprite_direction_style == "horizontal" then
        local dir = 0
        if (angle >= (math.pi / 2)) and (angle <= (3 * math.pi / 2)) then dir = 1 end
        return dir
      elseif enemy.sprite_direction_style == "single" then
        return 0
      else --4dir
        --switch case, no clever math:
        local dir = 0
        if (angle <= math.pi / 4) or (angle > 7 * math.pi / 4) then
          dir = 0
        elseif (angle <= 3 * math.pi / 4) and (angle > math.pi / 4) then
          dir = 1
        elseif (angle <= 5 * math.pi / 4) and (angle > 3 * math.pi / 4) then
          dir = 2
        elseif (angle <= 7 * math.pi / 4) and ( angle > 5 * math.pi / 4) then
          dir = 3
        end
        return dir
      end
    end
    --Otherwise an entity was passed as argument
    local angle = enemy:get_angle(target)
    if enemy.sprite_direction_style == "diagonal" then
      local dir = math.floor(angle / (math.pi / 2))
      return dir
    elseif enemy.sprite_direction_style == "horizontal" then
      if (angle >= (math.pi / 2)) and (angle <= (3 * math.pi / 2)) then
        return 1
      else
        return 0
      end
    elseif enemy.sprite_direction_style == "single" then
      return 0
    else --4dir
      return enemy:get_direction4_to(target)
    end
  end


  function enemy:get_angle_from_facing_direction()
    local angle
    local dir = sprite:get_direction()
    if enemy.sprite_direction_stype == "diagonal" then
      angle = dir * math.pi / 2 + math.pi / 4
    elseif enemy.sprite_direction_style == "horizontal" then
      angle = math.pi * dir --direction will either be 0 or 1
    elseif enemy.sprite_direction_style == "single" then
      angle = 0
    else --Assume 4-directional
      angle = dir * math.pi / 2
    end
    return angle
  end

  enemy:register_event("on_dying", function()
    for _, entity in pairs(enemy.attack_entities) do entity:remove() end
    enemy:set_traversable(true)
    enemy:show_hit_flash({ scale = 3 })
  end)


  function enemy:process_hit(props)
    local damage = props.damage or 1
    local damage_type = props.damage_type or "physical"
    local sound_override = props.sound_override
    local stagger_value = props.stagger_value or 0   
    local STAGGER_BUILDUP_RATIO = 0.25 --percentage of stagger value will build up
    local current_life = enemy:get_life()

    --break if can't be damaged right now:
    if current_life <= 0 then return end
    if enemy.invincible then return end
    if enemy.invulnerable then
      sol.sound.create("sword_tapping"):play()
      return
    end
    --Allow preprocess hit to handle things (will return true if it does):
    if enemy.preprocess_hit and enemy:preprocess_hit(damage, damage_type) then return end
    --Calculate damage input based on enemy properties:
    if enemy.calculate_damage_input then
      damage = enemy:calculate_damage_input(damage, damage_type)
    end
    --Actually do damage:
    enemy:remove_life(damage)
    --Show health bar:
    if not enemy.has_boss_bar then
      enemy:show_life_bar()
    end
    --Add stagger buildup:
    if enemy.build_up_stagger then
      stagger_value = stagger_value + enemy:get_stagger_buildup() --add any previously built up stagger
      enemy:build_up_stagger(math.floor(stagger_value * STAGGER_BUILDUP_RATIO)) --add more stagger for next hit
    end
    --Effects:
    enemy:play_hurt_sound(sound_override)
    if enemy.blood_splatter then
      local amount = 10
      if damage >= current_life then amount = 30 end
      enemy:blood_splatter(amount)
    end
    --Flash / Stagger
    enemy:show_hit_flash()
    if enemy.stagger_when_hurt then
      enemy:flash_with_stagger()
    -- if the enemy has been assigned a separate stagger resistance, compare it to the weapons ability to stagger(stagger_value)
    elseif stagger_value ~= nil and enemy.stagger_resistance and enemy.stagger_resistance <= stagger_value and not enemy.hyper_armor then
      enemy:flash_with_stagger()
    elseif enemy.stagger_life_percent <= (damage / enemy.max_life * 100) and not enemy.hyper_armor then
      enemy:flash_with_stagger()
    else
      enemy:flash_without_stagger()
    end
    --TODO: alert nearby enemies with a smaller range if the damage type is bullet
    enemy:on_hurt()
  end


  function enemy:play_hurt_sound(sound_override)
    local sound_id = "enemy_hurt"
    sound_id = "enemy_hurt_" .. math.random(1, 3)
    if sound_override then sound_id = sound_override end --TODO: confirm that these sounds exist at game statup time
    local sfx = sol.sound.create(sound_id)
    sfx:set_pitch(math.random(80, 120) / 100)
    sfx:play()
  end


  function enemy:flash()
    if not enemy_hurt_shader then return end
    for _, s in enemy:get_sprites() do
      s:set_shader(enemy_hurt_shader)
      sol.timer.start(map, hurt_flash_time, function()
        s:set_shader(nil)
      end)
    end
  end


  function enemy:flash_with_stagger(stagger_length)
    stagger_length = stagger_length or normal_stagger_length
    local sprite = enemy:get_sprite()
    sol.timer.stop_all(enemy)
    --remove weapon, if any
    for _, entity in pairs(enemy.attack_entities) do entity:remove() end
    enemy:alert_nearby_enemies()
    --Set hurt animation if present, otherwise flash the enemy's blend mode
    if sprite:has_animation("hurt") then
      sprite:set_animation"hurt"
      sol.timer.start(enemy:get_map(), hurt_flash_time, function()
        sprite:set_animation"walking"
      end)
    else
      enemy:flash()
    end
    --Push Back:
    if enemy:is_pushed_back_when_hurt() and enemy:get_life() > 0  then
      enemy.lock_facing = true
      local m = sol.movement.create"straight"
      local max_distance = 24 * (100 / (enemy.weight * 10))
      m:set_speed(200)
      m:set_angle(enemy:get_map():get_hero():get_angle(enemy))
      m:set_max_distance(max_distance)
      m:start(enemy)
      sol.timer.start(enemy, hurt_flash_time, function()
        enemy.lock_facing = false
      end)
    end
    if enemy:get_life() > 0 then
      sol.timer.start(enemy, hurt_flash_time + 10, function()
        enemy:stagger(stagger_length) --enemy:stagger will call enemy:restart() when finished
      end)
    end
    --Clear any stagger buildup:
    if enemy.set_stagger_buildup then
      enemy:set_stagger_buildup(0)
    end
  end


  function enemy:flash_without_stagger()
    enemy:flash()
    enemy:alert_nearby_enemies()
  end


  --Picks a foe to target for attacks, generally will be the hero
  function enemy:choose_target()
    --if a target entity has been set, unset it as we're choosing a new target
    --We don't reset that target value though, just unset it. The enemy can choose to save it if they wish
    enemy.target_entity = nil
    local target
    if enemy.choose_faction_target then
      target = enemy:choose_faction_target()
    else
      target = hero
      for h in map:get_entities_by_type("hero") do
        if (enemy:get_distance(h) < enemy:get_distance(target)) and h:exists() then
          target = h
        end
      end
    end
    return target or hero
    --Note: even for hero-allied enemies, this function will still return the hero as a target
  end


  function enemy:has_valid_target()
    local target = enemy:choose_target()
    if enemy.faction == "hero" and target:get_type() == "hero" then
      --hero is an invalid target for 'hero' faction
      return false
    end
    return target and true or false
  end


end

return applicator

