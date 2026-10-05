local item = ...
local game = item:get_game()

local magic_cost = 33
local windup_time = 100
local damage = 5
local initial_speed = 150
local num_projectiles = 4
local spread_angle = math.rad(75)
local projectile_distance = 72

function item:on_started()
  local savegame_variable = "possession_spell_hail"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
  item:set_ammo("_magic")
end
 

function item:on_using()
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local hero = game:get_hero()
  local map = game:get_map()

  hero:freeze()
  hero:set_animation("casting")
  sol.timer.start(hero, windup_time, function()
    hero:set_animation("throwing", function()
      hero:set_animation"stopped"
      hero:unfreeze()
      item:set_finished()
    end)
    local x, y, z = hero:get_position()
    local direction = hero:get_direction()
    for i = 0, num_projectiles - 1 do
      local projectile = map:create_ice_blast(x, y, z)
      projectile.harmless_to_hero = true
      projectile.damage = damage
      local m = sol.movement.create"straight"
      m:set_angle((direction * math.pi / 2) - (spread_angle / 2) + (spread_angle / (num_projectiles - 1) * i))
      m:set_speed(initial_speed)
      m:set_max_distance(projectile_distance)
      m:start(projectile)
    end
  end)

end
