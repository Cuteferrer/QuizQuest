local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 20,
  detection_distance = 200,
  abandon_hero_distance = 400,
  width = 32, height = 24,
  origin_x = 16, origin_y = 33,
})


local slash_attack = {
  windup_duration = 500,
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/spider_arm",
  weapon_windup_animation = "slash_windup",
  weapon_attack_animation = "slash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 600,
}

local ranged_attack = {
  windup_animation = "shooting_windup",
  windup_duration = 500,
  attack_animation = "shooting",
  projectile_offset_radius = 24,
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "webball",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/webball",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_duration = 1500,
}


local ranged_range = 48

function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif hero:is_status_effect_active("webbed") then
    enemy:approach_then_attack({
      approach_duration = 2000,
      speed = 75,
      attack_function = function()
        enemy:melee_attack(slash_attack)
      end
    })
  elseif distance >= ranged_range and enemy:has_los(hero) then
    enemy:ranged_attack(ranged_attack)
  else
    enemy:approach_then_attack({
      approach_duration = 1500,
      speed = 60,
      attack_function = function()
        enemy:melee_attack(slash_attack)
      end
    })
  end
end


