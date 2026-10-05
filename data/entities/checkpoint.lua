local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

local activate_radius = 128 --if you go this close to the checkpoint, it'll automatically activate to save your position for respawning

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  sprite = entity:get_sprite()
  entity:set_property("lighting_effect_type", "torch")

  --Entity for collision to atuto-activate checkpoint
  --[[
  local x, y, z = entity:get_position()
  local collider = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0,
    width = activate_radius, height = activate_radius,
  }
  collider:set_origin(activate_radius / 2, activate_radius / 2)
  collider:add_collision_test("overlapping", function(collider, other)
    if not collider.cooldown and other:get_type() == "hero" and other:get_distance(entity) <= activate_radius then
      collider.cooldown = true
      sol.timer.start(map, 30000, function() collider.cooldown = nil end)
      entity:auto_activate()
    end
  end)
  --]]

  --Create a sound source entity for a fire crackling sound:
  local x, y, z = entity:get_position()
  local sound_id = "fire"
  entity.sound_source = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    model = "environment/sound_source",
    properties = { {key = "sound_id", value = sound_id}, },
  }
  map.sound_source_sounds[sound_id] = nil
  require("scripts/modules/trillium/sound/sound_source_manager").start_sound(map, sound_id)
end


function entity:auto_activate()
  sol.audio.play_sound"fire_light"
  entity:sparkle_effect()
  local x, y, z = entity:get_position()
  entity:save_checkpoint(x, y + 24, z)
end


function entity:on_interaction()
  --Save checkpoint on interaction:
  entity:sparkle_effect()
  local x, y, z = entity:get_position()
  entity:save_checkpoint(x, y + 24, z)

  game:start_dialog("checkpoint.rest_question", function(answer)
    if answer == 1 then
      entity:activate_rest()
    end
  end)
end


function entity:activate_rest()
  sol.audio.play_sound"fire_light"
  game:start_flash()
  entity:sparkle_effect()
  map:clear_map_projectiles_and_stuff()
  entity:save_checkpoint()
  game:checkpoint_full_heal()
  game:refill_respawn_items()
  map:respawn_enemies()
  map:trigger_checkpoint_callbacks()
  game:save()
  game:stop_flash(10)
  sprite:set_ignore_suspend(true)
end


function entity:save_checkpoint(x, y, z)
  game:save_checkpoint(x, y, z)
  game:set_value("last_checkpoint_location_id", game:get_last_displayed_location())
end



function entity:sparkle_effect()
  local x, y, z = entity:get_position()
  for i=1, 12 do
    local sparkle = map:create_custom_entity{
      x=x, y=y, layer=z, direction=0, width=8, height=16,
      sprite = "entities/lantern_sparkle",
    }
    local sparkle_sprite = sparkle:get_sprite()
    sparkle_sprite:set_animation("sparkle_" .. math.random(1,2), function()
      sparkle:remove()
    end)
    sparkle:get_sprite():set_ignore_suspend(true)
    sparkle:set_drawn_in_y_order(true)
    local m = sol.movement.create"straight"
    m:set_speed(120)
    m:set_angle(math.random(100) * 2 * math.pi / 100)
    m:set_max_distance(math.random(16, 32))
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    m:start(sparkle)
  end
end
