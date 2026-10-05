local item = ...
local game = item:get_game()
local default_max_amount = 5
local base_damage = 20

function item:on_started()
  item:setup_amount_stuff(default_max_amount)
  item:set_fill_on_checkpoint()
end


function item:on_variant_changed()
  item:add_amount(5)
end


function item:throw_dart()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  local damage = game:calculate_hero_output_damage(base_damage, "alchemy")

  hero:set_animation("throwing", function()
    hero:unfreeze()
  end)
  sol.audio.play_sound("throw")
  local dart = map:create_custom_entity{
    x=x, y=y, layer=z, width=8, height=8, direction=0,
    sprite = "hero_projectiles/dart",
    model = "hero_projectiles/general",
  }
  dart:set_origin(4, 4)
  dart.damage = damage
  dart:add_collision_test("sprite", function(self, other)
    if other:get_type() == "enemy" then
      other:build_up_status_effect("poison", 80)
    end
  end)
  --adjust sprite a smidge to line up with throw better
  if direction % 2 == 0 then
    dart:get_sprite():set_xy(0, -4)
  end
  -- a little delay to match throwing animation better
  sol.timer.start(dart, 100, function()
    dart:shoot(direction * math.pi / 2)
  end)
end


function item:on_using()
  local hero = game:get_hero()
  if item:try_spend_ammo(1) then
    item:throw_dart()
    
  else
    sol.audio.play_sound"wrong"
    hero:unfreeze()
    item:set_finished()
  end
end
