local item = ...
local game = item:get_game()

local num_arrows = 7
local range = 250
local damage = 6

local chosen_targets = {}

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_arrow_storm")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(40) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  chosen_targets = {}
  for i = 1, num_arrows do
    local projectile = map:create_custom_entity{
      x=x, y=y, layer=z, width = 8, height = 8, direction = 0,
      model = "hero_projectiles/general",
      sprite = "hero_projectiles/spell_arrow",
    }
    projectile:set_origin(4, 5)
    projectile.damage = damage
    local target_enemy = item:choose_target()
    local aim_angle = target_enemy and hero:get_angle(target_enemy) or i * math.pi * 2 / num_arrows
    sol.timer.start(map, 20 * i, function()
      projectile:shoot(aim_angle)
    end)
    hero:set_animation("spear_attack_heavy", function()
      hero:set_animation"stopped"
      item:set_finished()
    end)
  end
end)


function item:choose_target()
  local hero = game:get_hero()
  local map = game:get_map()
  local aim_angle = hero:get_direction() * math.pi / 2
  local x, y, z = hero:get_position()
  local possible_enemies = {}
  local target_enemy = nil
  for e in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
    if e:get_type() == "enemy" then
      possible_enemies[e] = e
    end
  end
  for enemy in pairs(possible_enemies) do
    if hero:has_los(enemy) then
      local enemy_angle = hero:get_angle(enemy)
      local angle_diff = math.abs(aim_angle - enemy_angle)
      if angle_diff > math.pi then --impossible for difference to be more than 180, must be counting the long way around
        angle_diff = math.abs(enemy_angle - aim_angle)
      end
      enemy.spell_arrow_score = (angle_diff * 100) + hero:get_distance(enemy) * 2
      if (not target_enemy) or (target_enemy.spell_arrow_score > enemy.spell_arrow_score) then
        if not chosen_targets[enemy] and (enemy:get_life() > 0) then --if we've already chosen this one, or enemy is already dead, then skip
          chosen_targets[enemy] = true
          target_enemy = enemy
        end
      end
    end
  end
  return target_enemy
end
