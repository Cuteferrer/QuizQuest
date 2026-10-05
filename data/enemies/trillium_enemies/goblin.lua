local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 10,
  detection_distance = 200,
  abandon_hero_distance = 400,
})


local slash_attack_1 = {
  windup_duration = 300,
  windup_animation = "slash_windup",
  attack_animation = "slash_attack",
  weapon_sprite = "enemies/trillium_enemies/weapons/goblin_claws",
  weapon_windup_animation = "windup",
  weapon_attack_animation = "slash_attack",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 10,
}

local slash_attack_2 = {
  windup_duration = 10,
  windup_animation = "slash_windup_2",
  attack_animation = "slash_attack_2",
  weapon_sprite = "enemies/trillium_enemies/weapons/goblin_claws",
  weapon_windup_animation = "windup",
  weapon_attack_animation = "slash_attack_2",
  damage = 2,
  damage_type = "physical",
  recovery_duration = 700,
}

local slash_combo = {slash_attack_1, slash_attack_2}

function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if distance >= enemy.abandon_hero_distance then
    enemy:return_to_idle()
  else
    enemy:approach_then_attack({
      approach_duration = 1500,
      speed = 85,
      dist_threshold = 16,
      attack_function = function()
        local m = sol.movement.create"straight"
        m:set_max_distance(16)
        m:set_angle(enemy:get_angle(hero))
        m:start(enemy)
        enemy:melee_combo(slash_combo)
      end,
    })
  end
end
