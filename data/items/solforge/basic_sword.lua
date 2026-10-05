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
        windup_duration = 100,
        hero_windup_animation = "sword_windup",
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/sword_1",
        weapon_windup_animation = "swing_windup",
        weapon_attack_animation = "swing",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/sword_1",
        weapon_attack_animation = "reverse_swing",
        weapon_sound = "sword1",
        callback = step_forward,
      },
      {
        windup_duration = 80,
        hero_windup_animation = "sword_windup",
        hero_attack_animation = "sword_swing_forehand",
        weapon_sprite = "solforge_weapons/sword_1",
        weapon_windup_animation = "swing_windup",
        weapon_attack_animation = "swing",
        weapon_sound = "sword1",
        attack_power_bonus = 1,
        callback = step_forward,
      },
    },


    weapon_parameters = {
      attack_power = 2,
    },

  }
)
