local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite

require("enemies/gooseberry_enemies/behavior/goblin_behavior"):apply(enemy, {
  life = 8,
  damage = 1,
  alert_distance = 80,
  unalert_distance = 130,
  attack_distance = 48,
  wander_speed = 24,
  chase_speed = 60,
  attack_sprite = "enemies/gooseberry_enemies/attacks/slash",
  attack_sound = "sword3",
  attack_cooldown_length = 2000,
  has_melee_attack = true,
})

enemy:register_event("on_created", function(self)
end)
