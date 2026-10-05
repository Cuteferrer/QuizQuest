local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.modules.get_object("trillium_enemy_behavior"):apply_behavior(enemy, {
  life = 8,
  detection_distance = 64,
  abandon_hero_distance = 100,
})

--Overwrite several Trillium enemy methods due to unique behavior
function enemy:on_movement_changed(m)
end

function enemy:start_idle()
end

function enemy:decide_action()
end

enemy:register_event("on_created", function()
  enemy.home_x, enemy.home_y = enemy:get_position()
end)

enemy:register_event("on_restarted", function()
  enemy:stop_movement()
  enemy:get_sprite():set_animation"stopped"
  enemy:jump()
end)


function enemy:jump()
  local sprite = enemy:get_sprite()
  local angle = math.rad(math.random(1, 360))
  if enemy:get_distance(enemy.home_x, enemy.home_y) > 400 and (angle % 2 == 0) then
    angle = enemy:get_angle(enemy.home_x, enemy.home_y)
  end
  local m = sol.movement.create("straight")
  m:set_max_distance(math.random(64, 96))
  m:set_angle(angle)
  m:set_speed(30)
  m:start(enemy, function()
    enemy:pound()
  end)
  function m:on_obstacle_reached() enemy:pound() end
  sprite:set_animation("jumping", "floating")
end

function enemy:pound()
  local recovery_delay = math.random(500, 800)
  local attack_range = 200
  local sprite = enemy:get_sprite()
  enemy:stop_movement()
  sol.timer.start(enemy, 220, function()
    if enemy:get_distance(hero) <= attack_range then
      enemy:spoke_bullet_attack{
        projectile_sprite = "entities/enemy_projectiles/dandelion_seed",
        num_projectiles = 10,
        max_distance = 16,
        projectile_speed = 90,
        rotational_sprite = true,
      }
    end
  end)
  sprite:set_animation("falling", function()
    sprite:set_animation"stopped"
    sol.timer.start(enemy, recovery_delay, function()
      enemy:jump()
    end)
  end)
end

