local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 8,
  detection_distance = 200,
  abandon_hero_distance = 400,
})

local thrust_attack = {
  windup_duration = 500,
  windup_animation = "thrust_windup",
  attack_animation = "thrust_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_spear",
  weapon_windup_animation = "thrust_windup",
  weapon_attack_animation = "thrust_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 500,
}

local slam_attack = {
  windup_duration = 1000,
  windup_animation = "slam_windup",
  attack_animation = "slam_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_spear",
  weapon_windup_animation = "slam_windup",
  weapon_attack_animation = "slam_attack",
  damage = 6,
  damage_type = "physical",
  recovery_duration = 500,
}

local combo_1 = {
  windup_duration = 900,
  windup_animation = "thrust_windup",
  attack_animation = "thrust_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_spear",
  weapon_windup_animation = "thrust_windup",
  weapon_attack_animation = "thrust_attack",
  damage = 3,
  damage_type = "physical",
  recovery_duration = 10,
}

local combo_2 = {
  windup_duration = 10,
  windup_animation = "thrust_windup",
  attack_animation = "thrust_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_spear",
  weapon_windup_animation = "thrust_windup",
  weapon_attack_animation = "thrust_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 10,
}

local combo_3 = {
  windup_duration = 10,
  windup_animation = "thrust_windup",
  attack_animation = "thrust_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/hob_spear",
  weapon_windup_animation = "thrust_windup",
  weapon_attack_animation = "thrust_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 1100,
}

local combo_a = {combo_1, combo_2, combo_3}
local combo_b = {combo_1, combo_3}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  else
    enemy:approach_then_attack({
      approach_duration = 1500,
      speed = 60,
      attack_function = function()
        local rand = math.random(1, 3)
        if rand == 1 then
          enemy:melee_combo(combo_a)
        elseif rand == 2 then
          enemy:melee_combo(combo_b)
        else
          enemy:melee_attack(slam_attack)
        end
      end
    })
  end
end
