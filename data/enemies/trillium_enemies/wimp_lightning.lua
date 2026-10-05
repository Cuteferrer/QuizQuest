local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

enemy.lightning_immunity = true

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 20,
  detection_distance = 200,
  abandon_hero_distance = 500,
})

local ranged_attack = {
  windup_animation = "magic_charging",
  windup_duration = 500,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "lightningball",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/lightningball",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "fire",
  recovery_duration = 100,
}
local ranged_attack_2 = {
  windup_animation = "magic_charging",
  windup_duration = 50,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "lightningball",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/lightningball",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "fire",
  recovery_duration = 100,
}
local ranged_attack_3 = {
  windup_animation = "magic_charging",
  windup_duration = 50,
  attack_animation = "magic_shooting",
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "lightningball",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/lightningball",
  projectile_width = 8,
  projectile_height = 8,
  damage = 4,
  damage_type = "fire",
  recovery_duration = 1000,
}
local ranged_combo = {ranged_attack, ranged_attack_2, ranged_attack_3}
local ranged_combo_short = {ranged_attack, ranged_attack_3}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  local random = math.random(1,10)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif enemy:has_los(hero) and not enemy.has_shot and random < 4 then
    enemy:ranged_combo(ranged_combo)
    enemy.has_shot = true
    enemy.has_warped = false
  elseif enemy:has_los(hero) and not enemy.has_shot and random < 8 then
    enemy:ranged_combo(ranged_combo_short)
    enemy.has_shot = true
    enemy.has_warped = false
  elseif enemy:has_los(hero) and distance < 150 and not enemy.has_shot then
    enemy:summon_lightning()
    enemy.has_shot = true
    enemy.has_warped = false
  elseif not enemy.has_warped and enemy.has_shot then
    enemy.has_warped = true
    enemy.has_shot = false
    enemy:warp_away()
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

function enemy:summon_lightning()
  local sprite = enemy:get_sprite()
  local windup_duration = 2000
  local windup_animation = "aoe_charge"
  local windup_sound = "lightning_charge"
  local acquire_target_delay = 1500
  local attack_animation = "aoe_attack"
  local recovery_delay = 500
  enemy:stop_movement()
  sprite:set_animation(windup_animation)
  sol.audio.play_sound(windup_sound)
  local x,y,z = hero:get_position()
  sol.timer.start(enemy, acquire_target_delay, function()
    x,y,z = hero:get_position()
    map:create_lightning_bolt{
      x=x, y=y, layer=z, delay = windup_duration - acquire_target_delay,
    }
  end)
  sol.timer.start(enemy, windup_duration, function()
    sprite:set_animation(attack_animation, "stopped")
    sol.timer.start(enemy, recovery_delay, function()
      enemy:decide_action()
    end)
  end)
end
