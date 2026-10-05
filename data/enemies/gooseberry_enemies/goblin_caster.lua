local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite

local attack_cooldown_length = 3000

require("enemies/gooseberry_enemies/behavior/goblin_behavior"):apply(enemy, {
  life = 8,
  damage = 1,
  alert_distance = 180,
  unalert_distance = 240,
  attack_distance = 150,
  wander_speed = 24,
  chase_speed = 40,
  attack_sprite = "enemies/gooseberry_enemies/attacks/slash",
  attack_animation = "attack",
  attack_sound = "sword3",
  attack_cooldown_length = attack_cooldown_length,
  has_ranged_attack = true,
  has_melee_attack = false,
})

require("enemies/gooseberry_enemies/behavior/shoot"):apply(enemy)

enemy:register_event("on_created", function(self)
end)


function enemy:shoot()
  if enemy:get_movement() then enemy:get_movement():set_speed(1) end
  enemy:shoot_omnidirectional({
    speed = 160,
    breed = "gooseberry_enemies/projectiles/magic_thing"
  })
  sol.timer.start(enemy, 800, function()
    enemy.state = "alerted"
    enemy:decide_action()
  end)
  enemy.attack_cooldown = true
  sol.timer.start(map, attack_cooldown_length, function() enemy.attack_cooldown = false end)
end
