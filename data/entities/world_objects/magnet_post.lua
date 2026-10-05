local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local pull_speed = 250

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
end

function entity:react_to_magnet_gauntlet()
  local ex, ey, ez = entity:get_position()
  local mag_ball = game:get_item("inventory/magnet_gauntlet").mag_ball
  mag_ball:remove()
  local hero = game:get_hero()
  if hero:get_distance(entity) < 24 then
    hero:unfreeze()
    return
  end
  hero:unfreeze()

  local state = game:get_item("inventory/hookshot"):get_hookshot_state()
  hero:start_state(state)
  hero:set_animation"hookshot_pulling"

  local ray_sprite = hero:create_sprite("elements/magnet_energy")
  hero:bring_sprite_to_back(ray_sprite)
  ray_sprite:set_animation"ray"
  ray_sprite:set_xy(0, -8)
  ray_sprite:set_transformation_origin(0,0)
  ray_sprite:set_scale(hero:get_distance(ex, ey), 4)
  ray_sprite:set_rotation(hero:get_angle(ex, ey))

  function state:on_pre_draw()
    ex, ey, ez = entity:get_position()
    local distance = hero:get_distance(ex, ey)
    local angle = hero:get_angle(ex, ey)
    ray_sprite:set_scale(distance, 4)
    ray_sprite:set_rotation(angle)
  end
  function state:on_finished()
    hero:remove_sprite(ray_sprite)
  end

  local m = sol.movement.create"straight"
  m:set_angle(hero:get_angle(entity))
  m:set_max_distance(hero:get_distance(entity) - 16)
  m:set_speed(pull_speed)
  m:start(hero, function()
    hero:unfreeze()
  end)
  function m:on_obstacle_reached()
    hero:unfreeze()
  end
end

