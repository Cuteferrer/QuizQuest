local item = ...
local game = item:get_game()
local fuse_duration = 900
local damage = 75
local default_max_amount = 2

local num_explosions = 10
local fuse_min, fuse_max = 50, 800
local displacement_radius = 56

function item:on_started()
  item:setup_amount_stuff(default_max_amount)
  item:set_fill_on_checkpoint()
end


function item:on_variant_changed()
  item:add_amount(default_max_amount)
end


local function explosion_callback(grenade)
  local x, y, z = grenade:get_position()
  local map = item:get_map()
  for i = 1, num_explosions do
    sol.timer.start(map, math.random(fuse_min * i, fuse_max), function()
      map:create_explosion({
        x = x + math.random(displacement_radius * -1, displacement_radius),
        y = y + math.random(displacement_radius * -1, displacement_radius),
        layer = z,
        sprite = "items/explosion_small",
      })
    end)
  end
end


function item:on_using()
  local hero = game:get_hero()
  if item:try_spend_ammo(1) then
    local map = game:get_map()
    hero:throw_explosive({
      explosion_sprite = "items/explosion_small",
      explosion_callback = explosion_callback,
      fuse_duration = fuse_duration,
      explosion_props = {
        enemy_damage = damage,
        ignore_hero = true,
      }
    })
  else
    sol.audio.play_sound"wrong"
    hero:unfreeze()
    item:set_finished()
  end
end
