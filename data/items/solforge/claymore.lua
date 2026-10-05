local item = ...

local step_forward = function()
  local hero = sol.main.get_game():get_hero()
  hero:step_forward(16)
end

sol.modules.get_object("solforge"):temper_weapon(item,
  {
    item_id = item:get_name():gsub("/", "_"),

    attacks = {
      {
        windup_duration = 300,
        hero_windup_animation = "sword_windup",
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/claymore",
        weapon_windup_animation = "windup",
        weapon_attack_animation = "sword",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        windup_duration = 200,
        hero_windup_animation = "sword_windup_reverse",
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/claymore",
        weapon_windup_animation = "windup_reverse",
        weapon_attack_animation = "reverse_swing",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        windup_duration = 400,
        hero_windup_animation = "sword_windup",
        hero_attack_animation = "sword_swing_forehand",
        recovery_duration = 400,
        hero_recovery_animation = "stopped",
        weapon_sprite = "solforge_weapons/claymore",
        weapon_windup_animation = "windup",
        weapon_attack_animation = "endcombo",
        weapon_sound = "sword1",
        attack_power_bonus = 1,
      },
    },


    weapon_parameters = {
      attack_power = 4,
    },

  }
)
