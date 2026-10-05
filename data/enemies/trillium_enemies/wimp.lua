local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 20,
  detection_distance = 200,
  abandon_hero_distance = 500,
})

local ranged_attack = {
  windup_animation = "magic_charging",
  windup_time = 500,
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


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif enemy:has_los(hero) and not enemy.has_shot then
    enemy:ranged_attack(ranged_attack)
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

