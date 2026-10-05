local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 12,
  detection_distance = 200,
  abandon_hero_distance = 400,
})

local thrust_attack = {
  windup_animation = "thrust_windup",
  attack_animation = "thrust_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "thrust_windup",
  weapon_attack_animation = "thrust_attack",
  damage = 5,
  damage_type = "physical",
  recovery_duration = 500,
}

local slash_attack = {
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "slash_windup",
  weapon_attack_animation = "slash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 500,
}

local backslash_attack = {
  windup_duration = 300,
  windup_animation = "backslash_windup",
  attack_animation = "backslash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "backslash_windup",
  weapon_attack_animation = "backslash_attack",
  damage = 1,
  damage_type = "physical",
  recovery_duration = 200,
}


local combo_1 = {
  windup_duration = 700,
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "slash_windup",
  weapon_attack_animation = "slash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 20,
}

local combo_2 = {
  windup_duration = 50,
  windup_animation = "backslash_windup",
  attack_animation = "backslash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "backslash_windup",
  weapon_attack_animation = "backslash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 50,
}

local combo_2b = {
  windup_duration = 50,
  windup_animation = "backslash_windup",
  attack_animation = "backslash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "backslash_windup",
  weapon_attack_animation = "backslash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 600,
}


local combo_3 = {
  windup_duration = 200,
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_sword",
  weapon_windup_animation = "slash_windup",
  weapon_attack_animation = "slash_attack",
  damage = 3,
  damage_type = "physical",
  recovery_duration = 800,
}


local slash_combo = {combo_1, combo_2, combo_3}
local short_combo = {combo_1, combo_2b}


local ranged_attack = {
  windup_animation = "crossbow_windup",
  windup_duration = 800,
  projectile_model = "enemy_projectiles/generic_projectile",
  generic_projectile_type = "arrow",
  aim_type = "any",
  projectile_sprite = "entities/enemy_projectiles/arrow",
  projectile_width = 8,
  projectile_height = 8,
  damage = 2,
  damage_type = "physical",
  recovery_duration = 500,
}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  elseif distance >= 140 and enemy:has_los(hero) then
    enemy:ranged_attack(ranged_attack)
  else
    enemy:approach_then_attack({
      approach_duration = 1500,
      speed = 60,
      attack_function = function()
        local rand = math.random(1, 4)
        if rand == 1 then
          enemy:melee_combo(slash_combo)
        elseif rand == 2 then
          enemy:melee_combo(short_combo)
        elseif enemy:is_aligned(hero, 10) then
          enemy:melee_attack(thrust_attack)
        else
          enemy:melee_attack(backslash_attack)
        end
      end
    })
  end
end
