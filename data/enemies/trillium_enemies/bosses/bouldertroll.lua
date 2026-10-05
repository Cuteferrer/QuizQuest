local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 36,
  detection_distance = 500,
  abandon_hero_distance = 800,
  stunlock_limit = 5,
  sprite_direction_style = "horizontal",
  width = 32,
  height = 32,
})

--Boss Death:
enemy:register_event("on_dying", function()
  enemy:boss_death("stopped")
end)


local ranged_boulder = {
  windup_animation = "throwing_windup_rock",
  attack_animation = "throwing",
  attack_sound = "bow",
  projectile_sprite = "entities/enemy_projectiles/boulder",
  projectile_properties = {
    speed = 200,
  },
  damage = 2,
  recovery_duration = 1000,
}


local line_attack = {
  windup_animation = "smash_windup",
  windup_duration = 1000,
  attack_animation = "smash",
  attack_sound = "ground_burst",
  damage = 2,
  range = 300,
}


enemy:register_event("on_restarted", function()
  enemy:set_invincible()
  enemy:set_attack_consequence("sword", "protected")
end)


function enemy:decide_action()
  local distance = enemy:get_distance(hero)
  local random = math.random(1, 100)

  if distance < 48 and random < 35 then
    enemy:step_away()

  elseif random < 30 then
    enemy:ranged_attack(ranged_boulder)

  elseif random < 50 then
    enemy:slam()

  elseif random < 70 then
    enemy:approach_then_attack{
      attack_function = function() enemy:slam() end,
    }

  else
    enemy:approach_hero{ approach_duration = 500, }

  end
end


function enemy:slam()
  enemy:line_attack(line_attack)
  sol.audio.play_sound"running_obstacle"
  sol.timer.start(enemy, line_attack.windup_duration + 60, function()
    local x, y, z = enemy:get_position()
    local attack = map:create_custom_entity{
      x=x, y=y + 16, layer=z, direction = 0, width = 16, height = 16,
      sprite = "entities/enemy_projectiles/dust_attack_big",
      model = "enemy_projectiles/general_attack",
    }
    attack.damage = 2
    attack:remove_after_animation()
  end)
end


function enemy:step_away()
  enemy:retreat{
    speed = 200,
    max_distance = 48,
    animation = "walking",
    lock_facing = true,
  }
end



function enemy:stunlock_break()
  sol.timer.stop_all(enemy)
  enemy:set_invincible()
  enemy:retreat{
    speed = 250,
    max_distance = 64,
    animation = "walking",
    lock_facing = true,
  }
  sol.timer.start(enemy, 400, function()
    enemy:set_default_attack_consequences()
  end)
end



function enemy:crack(crack_damage)
  enemy:stagger(150)
  local x, y, z = enemy:get_position()
  enemy.crack_counter = (enemy.crack_counter or 0) + (crack_damage or 1)
  if enemy.crack_counter >= 3 then
    enemy.crack_counter = 0
    sol.audio.play_sound("breaking_stone")
    sol.audio.play_sound("breaking_vase")
    sol.audio.play_sound("boss_hurt")
    map:create_custom_entity{
      x=x, y=y - 16, layer=z + 1, direction = 0, width = 16, height = 16,
      sprite = "entities/enemy_projectiles/dust_attack_big",
      model = "ephemeral_effect",
    }
    enemy:posture_break()
  else
    map:create_custom_entity{
      x=x, y=y - 16, layer=z + 1, direction = 0, width = 16, height = 16,
      sprite = "entities/enemy_projectiles/debris_attack",
      model = "ephemeral_effect",
    }
    sol.audio.play_sound("sword_tapping")
    sol.audio.play_sound("breaking_stone")
  end
end


local STUN_DURATION = 3000
function enemy:posture_break(callback)
  sol.timer.start(enemy, 10, function()

    sol.timer.stop_all(enemy)
    enemy:set_default_attack_consequences()
    local sprite = enemy:get_sprite()
    sprite:set_animation("hurt")
    sol.timer.start(enemy, 200, function()
      sprite:set_animation("stunned")
      sol.timer.start(enemy, STUN_DURATION, function()
        enemy:set_invincible()
        enemy:set_attack_consequence("sword", "protected")
        sprite:set_animation("healing", function()
          sprite:set_animation("stopped")
          enemy:restart()
        end)
        if callback then callback() end
      end)
    end)

  end)
end


function enemy:react_to_explosion()
  enemy:crack(3)
end


--Get hit by heavy ball:
function enemy:react_to_heavy_ball(ball)
  enemy:crack()
  --Bounce ball off:
  local m = sol.movement.create("straight")
  m:set_angle(enemy:get_angle(ball))
  m:set_speed(250)
  m:set_max_distance(48)
  m:set_smooth(false)
  m:start(ball)
end

