local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 5,
  detection_distance = 200,
  abandon_hero_distance = 400,
})


local slash_attack = {
  windup_duration = 300,
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/goblin_sword",
  weapon_windup_animation = "slash_windup",
  weapon_attack_animation = "slash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 600,
}

local ranged_attack = {
  windup_animation = "bow_windup",
  windup_duration = 800,
  attack_animation = "bow_attack",
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "arrow",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/arrow",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_duration = 1500,
}


local ranged_combo = {ranged_attack1, ranged_attack2, ranged_attack3}
local attack_range = 60
local melee_range = 32
local attack_cooldown_time = 3000

function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  enemy:get_sprite():set_direction(enemy:get_direction4_to(hero))
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif distance >= attack_range and enemy:has_los(hero) and not enemy.attack_cooldown then
    enemy:ranged_attack(ranged_attack)
    enemy.attack_cooldown = true
    sol.timer.start(map, attack_cooldown_time, function() enemy.attack_cooldown = false end)
  elseif distance >= attack_range and not enemy:has_los(hero) and not enemy.attack_cooldown then
    --shoot even if you won't hit
    enemy:ranged_attack(ranged_attack)
    enemy.attack_cooldown = true
    sol.timer.start(map, attack_cooldown_time, function() enemy.attack_cooldown = false end)
  elseif distance <= melee_range then
    enemy:melee_attack(slash_attack)
  elseif distance > melee_range and distance < attack_range then
    enemy:retreat()
  else
    sol.timer.start(enemy, 300, function() enemy:decide_action() end)
  end
end


function enemy:circular_adjust_position()
  local movement_duration = 500
  local m = sol.movement.create"circle"
  m:set_center(hero)
  m:set_radius(enemy:get_distance(hero))
  m:set_angle_from_center(hero:get_angle(enemy))
  m:set_angular_speed(1)
  m:set_duration(movement_duration)
  if math.random(1,2) == 2 then m:set_clockwise() end
  m:start(enemy)
  sol.timer.start(enemy, movement_duration - 10, function()
    enemy:stop_movement()
    enemy:decide_action()    
  end)
end
