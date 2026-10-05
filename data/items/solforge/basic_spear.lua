local item = ...

local step_forward = function()
  local hero = sol.main.get_game():get_hero()
  local m = sol.movement.create("straight")
  local direction = hero:get_direction()
  m:set_angle(direction * math.pi / 2)
  m:set_max_distance(8)
  m:start(hero)
end

sol.modules.get_object("solforge"):temper_weapon(item,
  {
    item_id = item:get_name():gsub("/", "_"),

    attacks = {
      {
        hero_attack_animation = "spear_attack",
        weapon_sprite = "solforge_weapons/spear_1",
        weapon_attack_animation = "spear",
        weapon_sound = "sword4",
        callback = step_forward,
      },
      {
        hero_attack_animation = "spear_attack",
        weapon_sprite = "solforge_weapons/spear_1",
        weapon_attack_animation = "spear",
        weapon_sound = "sword4",
        callback = step_forward,
      },
      {
        hero_attack_animation = "spear_attack",
        weapon_sprite = "solforge_weapons/spear_1",
        weapon_attack_animation = "spear",
        weapon_sound = "sword4",
        callback = step_forward,
      },
      {
        hero_attack_animation = "spear_attack_heavy",
        weapon_sprite = "solforge_weapons/spear_1",
        weapon_attack_animation = "heavy_attack",
        weapon_sound = "sword4",
        attack_power_bonus = 2,
      },
    },



    weapon_parameters = {
      attack_power = 1,
      weight = 10,
      durability = 100,
    }
  }
)
