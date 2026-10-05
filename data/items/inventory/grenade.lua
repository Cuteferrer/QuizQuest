local item = ...
local game = item:get_game()
local fuse_duration = 600
local initial_speed = 300
local speed_loss = 40

function item:on_started()
  item:set_savegame_variable("possession_grenade")
  item:set_amount_savegame_variable("amount_grenade")
  item:set_max_amount(999)
  item:set_amount(30)
  item:set_assignable(true)
  item:set_ammo("_amount")
end


function item:on_obtaining()
  item:add_amount(30)
end
 

function item:on_using()
  local hero = game:get_hero()
  if item:try_spend_ammo(1) then
    local map = game:get_map()
    hero:freeze()
    hero:set_animation("throwing", function()
      hero:set_animation"stopped"
      hero:unfreeze()
      item:set_finished()
    end)
    sol.timer.start(map, 270, function()
      sol.audio.play_sound"throw"
      local x, y, z = hero:get_position()
      local direction = game:get_direction_held()
      local grenade = map:create_custom_entity{
        x=x, y=y, layer=z,
        width=16, height=16, direction = 0,
        sprite = "hero_projectiles/grenade",
      }
      local sprite = grenade:get_sprite()
      sprite:set_animation("falling", "rolling")
      grenade:set_can_traverse("hero", true)
      local m = sol.movement.create"straight"
      m:set_speed(initial_speed)
      m:set_angle(direction * math.pi / 4)
      m:start(grenade)
      local elapsed_time = 0
      local step = 100
      sol.timer.start(grenade, step, function()
        elapsed_time = elapsed_time + step
        if elapsed_time < fuse_duration then
          m:set_speed(m:get_speed() - speed_loss)
          return true
        else
          x, y, z = grenade:get_position()
          grenade:remove()
          local explosion = map:create_explosion{
            x=x, y=y, layer=z,
          }
          --local explosion_sprite = explosion:create_sprite"entities/explosion_shockwave"
          --explosion_sprite:set_scale(1.5, 1.5)
          sol.audio.play_sound"explosion"
        end
      end)
    end)
  else
    sol.audio.play_sound"wrong"
    hero:unfreeze()
    item:set_finished()
  end
end
