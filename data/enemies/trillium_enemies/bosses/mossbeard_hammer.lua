local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 36,
  detection_distance = 500,
  abandon_hero_distance = 800,
  stunlock_limit = 5,
})

--Boss Death:
enemy:register_event("on_dying", function()
  enemy:boss_death("stopped")
end)

local slam_attack = {
  windup_animation = "slam_windup",
  windup_delay = 800,
  attack_animation = "slam_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "slam_windup",
  weapon_attack_animation = "slam_attack",
  damage = 4,
  has_aoe = true,
  aoe_damage = 2,
  aoe_scale = {1.2, 1.2},
  aoe_screenshake = 24,
  aoe_offset = 24,
  aoe_sound = "running_obstacle",
  damage_type = "physical",
  recovery_delay = 700,
}

local swipe_attack = {
  windup_animation = "swipe_windup",
  windup_delay = 300,
  attack_animation = "swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "swipe_windup",
  weapon_attack_animation = "swipe_attack",
  damage = 2,
  damage_type = "physical",
  recovery_delay = 200,
}

local reverse_swipe_attack = {
  windup_animation = "reverse_swipe_windup",
  windup_delay = 300,
  attack_animation = "reverse_swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "reverse_swipe_windup",
  weapon_attack_animation = "reverse_swipe_attack",
  damage = 1,
  damage_type = "physical",
  recovery_delay = 200,
}


local combo_a1 = {
  windup_animation = "swipe_windup",
  windup_delay = 500,
  attack_animation = "swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "swipe_windup",
  weapon_attack_animation = "swipe_attack",
  damage = 2,
  damage_type = "physical",
  recovery_delay = 20,
}

local combo_a2 = {
  windup_animation = "reverse_swipe_windup",
  windup_delay = 200,
  attack_animation = "reverse_swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "reverse_swipe_windup",
  weapon_attack_animation = "reverse_swipe_attack",
  damage = 2,
  damage_type = "physical",
  recovery_delay = 700,
}

local combo_a = {combo_a1, combo_a2}

local ranged_attack = {
  windup_animation = "casting",
  windup_time = 500,
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "arrow",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/dandelion_seed",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_delay = 10,
}
local ranged_attack_2 = {
  windup_animation = "casting",
  windup_time = 100,
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "arrow",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/dandelion_seed",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_delay = 10,
}
local ranged_attack_3 = {
  windup_animation = "casting",
  windup_time = 100,
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "arrow",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/dandelion_seed",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_delay = 800,
}


local ranged_combo = {ranged_attack, ranged_attack_2, ranged_attack_3}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif distance >= 150 then
    enemy:ranged_combo(ranged_combo)
  else
    local rand = math.random(1,100)
    if rand <= 30 then
      enemy:destroy_floor_jump()
    else
      enemy:approach_then_attack({
        approach_duration = 1500,
        speed = 40,
        dist_threshold = 48,
        attack_function = function()
          if rand <= 55 then
            enemy:melee_combo(combo_a)
          elseif rand <= 80 then
            enemy:melee_attack(slam_attack)
          else
            enemy:melee_attack(reverse_swipe_attack)
          end
        end
      })
    end
  end
end


local jump_landing_aoe_props = {
  aoe_damage = 4,
  aoe_scale = {1.2, 1.2},
  aoe_screenshake = 24,
  aoe_offset = 0,
  aoe_sound = "running_obstacle",
  aoe_delay = 10,
}

function enemy:destroy_floor_jump()
  local sprite = enemy:get_sprite()
  sprite:set_animation"crouching"
  sol.timer.start(enemy, 300, function()
    enemy:set_layer(enemy:get_layer() + 1)
    sprite:set_animation"jumping"
    sol.audio.play_sound"jump"
    local rand = math.random(1, 3)
    local landings = {"left", "center", "right"}
    local jump_direction = landings[rand]
    --move to landing
    local target_entity = map:get_entity("boss_landing_target_" .. jump_direction)
    local m = sol.movement.create"straight"
    m:set_angle(enemy:get_angle(target_entity))
    m:set_max_distance(enemy:get_distance(target_entity))
    m:set_speed(180)
    m:start(enemy, function()
      sprite:set_animation("landing", function()
        sprite:set_animation("stopped")
        enemy:set_layer(enemy:get_layer() - 1)
        enemy:create_melee_aoe(jump_landing_aoe_props)
        if map:has_entities("boss_floor_tile_" .. jump_direction) then
          map:get_entity("boss_hole_wall_" .. jump_direction):set_enabled(true)
          for tile in map:get_entities("boss_floor_tile_" .. jump_direction) do
            sol.timer.start(map, math.random(300,800), function() tile:remove() end)
          end
        end
        sol.timer.start(enemy, 800, function() enemy:decide_action() end)
      end)
    end)
  end)
end


function enemy:stunlock_break()
  sol.timer.stop_all(enemy)
  enemy:set_invincible()
  enemy:destroy_floor_jump()
  sol.timer.start(enemy, 400, function()
    enemy:set_default_attack_consequences()
  end)
end


--Hack because the weapons are quicker than the i-frames of enemies
--[[
function enemy:process_hit(attack_power)
  local sprite = enemy:get_sprite()
  sol.audio.play_sound"enemy_hurt"
  sprite:set_blend_mode"add"
  sol.timer.start(map, 100, function() sprite:set_blend_mode"blend" end)
  enemy:remove_life(attack_power)
end
--]]
