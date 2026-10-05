local item = ...

sol.modules.get_object("solforge"):temper_weapon(item,
  {
    item_id = item:get_name():gsub("/", "_"),

    attacks = {
      {
        hero_windup_animation = "sword_windup",
        windup_duration = 400,
        hero_attack_animation = "sword",
        weapon_sprite = "solforge_weapons/axe_1",
        weapon_windup_animation = "windup",
        weapon_attack_animation = "axe",
        weapon_sound = "sword1",
      },
      {
        hero_windup_animation = "sword_windup_reverse",
        windup_duration = 200,
        hero_attack_animation = "sword_swing_backhand",
        weapon_sprite = "solforge_weapons/axe_1",
        weapon_windup_animation = "windup_reverse",
        weapon_attack_animation = "axe_reverse",
        weapon_sound = "sword1",
      },
    },

    weapon_parameters = {
      attack_power = 5,
      weight = 10,
    }
  }
)
