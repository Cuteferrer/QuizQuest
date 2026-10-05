local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 30,
  detection_distance = 150,
  abandon_hero_distance = 600,
})

local slam_attack = {
  windup_animation = "slam_windup",
  windup_duration = 800,
  attack_animation = "slam_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "slam_windup",
  weapon_attack_animation = "slam_attack",
  damage = 6,
  has_aoe = true,
  aoe_damage = 4,
  aoe_sound = "running_obstacle",
  aoe_offset = 24,
  damage_type = "physical",
  recovery_duration = 500,
}

local swipe_attack = {
  windup_animation = "swipe_windup",
  windup_duration = 300,
  attack_animation = "swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "swipe_windup",
  weapon_attack_animation = "swipe_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 200,
}

local reverse_swipe_attack = {
  windup_animation = "reverse_swipe_windup",
  windup_duration = 300,
  attack_animation = "reverse_swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "reverse_swipe_windup",
  weapon_attack_animation = "reverse_swipe_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 200,
}


local combo_a1 = {
  windup_animation = "swipe_windup",
  windup_duration = 500,
  attack_animation = "swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "swipe_windup",
  weapon_attack_animation = "swipe_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 20,
}

local combo_a2 = {
  windup_animation = "reverse_swipe_windup",
  windup_duration = 200,
  attack_animation = "reverse_swipe_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/greathammer",
  weapon_windup_animation = "reverse_swipe_windup",
  weapon_attack_animation = "reverse_swipe_attack",
  damage = 4,
  damage_type = "physical",
  recovery_duration = 700,
}


local combo_a = {combo_a1, combo_a2}


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  else
    enemy:approach_then_attack({
      approach_duration = 1500,
      speed = 60,
      attack_function = function()
        local rand = math.random(1,4)
        if rand == 1 then
          enemy:melee_combo(combo_a)
        elseif rand == 2 then
            enemy:melee_attack(slam_attack)
        else
          enemy:melee_attack(reverse_swipe_attack)
        end
      end
    })
  end
end
