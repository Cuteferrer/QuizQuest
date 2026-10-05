local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 40,
  detection_distance = 200,
  abandon_hero_distance = 500,
})

local ranged_attack1 = {
  windup_animation = "magic_charging",
  windup_duration = 500,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/generic_projectile",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "magic",
  recovery_duration = 100,
}
local ranged_attack2 = {
  windup_animation = "magic_charging",
  windup_duration = 50,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/generic_projectile",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "magic",
  recovery_duration = 100,
}
local ranged_attack3 = {
  windup_animation = "magic_charging",
  windup_duration = 50,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/generic_projectile",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "magic",
  recovery_duration = 100,
}
local ranged_attack4 = {
  windup_animation = "magic_charging",
  windup_duration = 50,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/generic_projectile",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "magic",
  recovery_duration = 1000,
}

local ranged_attack_quick = {
  windup_animation = "magic_charging",
  windup_duration = 300,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/generic_projectile",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "magic",
  recovery_duration = 50,
}

local aoe_basic = {
  windup_duration = 220,
  windup_animation = "aoe_attack",
  attack_animation = "aoe_attack",
  attack_entity_duration = 600,
  recovery_duration = 500
}
local aoe_fire = {
  windup_duration = 220,
  windup_animation = "aoe_charge",
  attack_animation = "aoe_attack",
  attack_entity_model = "elements/flame",
  attack_entity_duration = 600,
  recovery_duration = 500
}
local aoe_ice = {
  windup_duration = 220,
  windup_animation = "aoe_attack",
  attack_animation = "aoe_attack",
  attack_entity_model = "elements/ice_blast",
  attack_entity_duration = 600,
  recovery_duration = 500
}
local aoe_lightning = {
  windup_duration = 220,
  windup_animation = "aoe_attack",
  attack_animation = "aoe_attack",
  attack_entity_model = "elements/lightning_zap",
  attack_entity_duration = 600,
  recovery_duration = 500
}

local ranged_combo = {ranged_attack1, ranged_attack4}
local ranged_combo2 = {ranged_attack1, ranged_attack2, ranged_attack3, ranged_attack4}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif enemy:has_los(hero) and not enemy.has_shot and enemy:get_distance(hero) > 50 then
    enemy:decide_projectile_attack()
  elseif enemy:has_los(hero) and not enemy.has_shot then
    enemy:decide_aoe_attack()
  elseif not enemy.has_warped and enemy.has_shot then
    enemy.has_warped = true
    enemy.has_shot = false
    enemy:warp_away({range = 200,})
  elseif distance < 40 then
    if math.random(1,4) == 1 then
      enemy:warp_away()
    else
      enemy:retreat()
    end
  else
    enemy:approach_hero({
      dist_threshold = 40,
      approach_duration = 500,
    })
  end
end


function enemy:decide_projectile_attack()
  local rand = math.random(1,6)
  if rand <= 2 then
    enemy:ranged_combo(ranged_combo2)
  elseif rand == 6 then
    enemy:ranged_attack(ranged_attack_quick)
  else
    enemy:ranged_combo(ranged_combo)
  end
  enemy.has_shot = true
  enemy.has_warped = false
end


function enemy:decide_aoe_attack()
  enemy.fire_immunity = false
  enemy.ice_immunity = false
  enemy.lightning_immunity = false

  local rand = math.random(1,4)
  if rand == 1 then
    enemy:circle_bursts_attack(aoe_basic)
  elseif rand == 2 then
    enemy.fire_immunity = true
    enemy:circle_bursts_attack(aoe_fire)
  elseif rand == 3 then
    enemy.ice_immunity = true
    enemy:circle_bursts_attack(aoe_ice)
  elseif rand == 4 then
    enemy.lightning_immunity = true
    enemy:circle_bursts_attack(aoe_lightning)
  end
  enemy.has_shot = true
  enemy.has_warped = false
end

