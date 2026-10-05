local item = ...
local game = item:get_game()

local magic_cost = 35
local num_arrows = 3
local range = 400
local damage = 7
local projectile_cast_delay = 250

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_arcane_dart")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()

  hero:set_animation("casting")
  sol.timer.start(hero, 100, function()
    for i = 1, num_arrows do
      sol.timer.start(hero, projectile_cast_delay * i, function()
        sol.audio.play_sound("frost2")
        local projectile = map:create_custom_entity{
          x=x, y=y, layer=z, width = 8, height = 8, direction = 0,
          model = "hero_projectiles/general",
          sprite = "hero_projectiles/arcane_bolt",
        }
        projectile:set_origin(4, 5)
        projectile.damage = damage
        projectile.speed = 200
        local target_enemy = item:choose_target()
        local aim_angle = target_enemy and hero:get_angle(target_enemy) or (direction* math.pi/2)
        projectile:shoot(aim_angle)
        if target_enemy then projectile:track_target(target_enemy) end
      end)
    end
  end)
  sol.timer.start(hero, num_arrows * projectile_cast_delay, function()
    hero:unfreeze()
  end)
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
        if (angle_diff < math.rad(100)) and (enemy:get_life() > 0) then --if it's more than 90 off, the enemy isn't remotely in front of us, also skip if enemy is already dead
          target_enemy = enemy
        end
      end
    end
  end
  return target_enemy
end
