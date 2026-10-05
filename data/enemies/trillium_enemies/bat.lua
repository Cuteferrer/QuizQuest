local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

enemy.exp = 10
enemy.weight = 3
enemy.money = 0


sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 2,
  detection_distance = 96,
  abandon_hero_distance = 150,
})

local ram_attack = {
  windup_animation = "ramming_windup",
  windup_sound = "enemies/bat_1",
  attack_animation = "ramming",
  weapon_sprite = "enemies/trillium_enemies/bat",
  weapon_attack_animation = "ramming_slice",
  max_distance = 96,
}


enemy:register_event("on_restarted", function()
  enemy:set_traversable(true)
  enemy:set_obstacle_behavior("flying")
end)


function enemy:on_movement_changed(m)
  if not enemy.lock_facing then
    enemy.facing_angle = m:get_angle() or 0
    local angle = enemy.facing_angle
    local direction = 0
    if angle > 0 and angle < math.pi / 2 then
      direction = 1
    elseif angle >= math.pi / 2 and angle < math.pi then
      direction = 2
    elseif angle >= math.pi and angle < 3 * math.pi / 2 then
      direction = 3
    elseif angle >= 3 * math.pi / 2 and angle < 2 * math.pi then
      direction = 0
    end
    enemy:get_sprite():set_direction(direction)
  end
end


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  if (distance >= enemy.abandon_hero_distance) then
    enemy:return_to_idle()
  elseif not enemy.ram_cooldown then
    enemy:ram_attack(ram_attack)
    enemy.ram_cooldown = true
    sol.timer.start(map, 2000, function()
      enemy.ram_cooldown = false
    end)
  else
    enemy:stop_movement()
    enemy:get_sprite():set_direction(enemy:get_direction4_to(hero))
    sol.timer.start(enemy, 500, function()
      enemy:decide_action()
    end)
  end
end




