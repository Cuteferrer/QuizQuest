local item = ...

local step_forward = function()
  local hero = sol.main.get_game():get_hero()
  local m = sol.movement.create("straight")
  local direction = hero:get_direction()
  m:set_angle(direction * math.pi / 2)
  m:set_max_distance(4)
  m:start(hero)
end

sol.modules.get_object("solforge"):temper_weapon(item,
  {
    item_id = item:get_name():gsub("/", "_"),

    attacks = {
      {
        windup_duration = 100,
        hero_windup_animation = "sword_windup",
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/dagger_1",
        weapon_windup_animation = "slash_windup",
        weapon_attack_animation = "slash",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        hero_attack_animation = "sword_swing_backhand",
        weapon_sprite = "solforge_weapons/dagger_1",
        weapon_attack_animation = "backslash",
        weapon_sound = "sword1",
      },
      {
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/dagger_1",
        weapon_windup_animation = "slash_windup",
        weapon_attack_animation = "slash",
        weapon_sound = "sword1",
        attack_power_bonus = 1,
        callback = step_forward,
      },
      {
        hero_attack_animation = "sword_swing_backhand",
        weapon_sprite = "solforge_weapons/dagger_1",
        weapon_attack_animation = "backslash",
        weapon_sound = "sword1",
        attack_power_bonus = 1,
      },
      {
        windup_duration = 50,
        hero_windup_animation = "spear_windup",
        hero_attack_animation = "spear_attack",
        weapon_sprite = "solforge_weapons/dagger_1",
        weapon_windup_animation = "thrust_windup",
        weapon_attack_animation = "thrust",
        weapon_sound = "sword1",
        callback = step_forward,
        recovery_duration = 450,
        hero_recovery_animation = "sword_windup",
        attack_power_bonus = 2,
      },
    },


    weapon_parameters = {
      attack_power = 1,
    },

  }
)
