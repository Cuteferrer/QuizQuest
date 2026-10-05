local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  local animation_set = entity:get_sprite():get_animation_set()
  entity:remove_sprite()
  entity:create_sprite(animation_set, "main")
  entity:set_drawn_in_y_order(true)
  local shadow_sprite = entity:create_sprite"shadows/shadow_small"
  entity:bring_sprite_to_back(shadow_sprite)
  if entity:get_property("treasure") then
    entity.treasure = game:get_item(entity:get_property("treasure"))
    entity.treasure_variant = entity:get_property"treasure_variant"
  end
  entity.notice_hero_distance = entity:get_property"notice_hero_distance" or 24
  entity.movement_type = entity:get_property"movement_type" or "butterfly"

  --sparkle
  sol.timer.start(entity, math.random(1500, 2200), function()
    local sparkle = entity:create_sprite("entities/sparkle")
    sparkle:set_xy(math.random(-8, 8), math.random(-16, 0))
    sol.timer.start(entity, 500, function()
      entity:remove_sprite(sparkle)
    end)
    return true
  end)

  if entity.movement_type == "butterfly" then
    entity:start_butterfly_movement()
  elseif entity.movement_type == "dragonfly" then
    entity:start_dragonfly_movement()
  end

  entity:check_for_hero()
end


function entity:on_movement_changed(m)
  if m:get_speed() < 1 then return end
  local sprite = entity:get_sprite("main")
  local num_directions = sprite:get_num_directions()
  if num_directions == 4 then
    sprite:set_direction(m:get_direction4())
  elseif num_directions == 2 then
    if m:get_angle() > math.pi / 2 and m:get_angle() < 3 * math.pi / 2 then
      sprite:set_direction(1)
    else
      sprite:set_direction(0)
    end
  end
end


function entity:check_for_hero()
  if entity:get_distance(hero) <= entity.notice_hero_distance then
    entity:run_away()
  else
    sol.timer.start(entity, 700, function()
      entity:check_for_hero()
    end)
  end
end


function entity:run_away()
  entity:stop_movement()
  sol.timer.stop_all(entity)
  local speed
  if entity.movement_type == "butterfly" then
    speed = 75
  else
    speed = 150
  end
  local m = sol.movement.create"straight"
  m:set_angle(hero:get_angle(entity))
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  m:start(entity)
  sol.timer.start(entity, 2500, function()
    entity:get_sprite():fade_out(20, function()
      entity:remove()
    end)
  end)
end


function entity:start_butterfly_movement()
  local m = sol.movement.create"random"
  m:set_speed(10)
  m:start(entity)
end


function entity:start_dragonfly_movement()
  local m = sol.movement.create"straight"
  m:set_angle(math.rad(math.random(0, 360)))
  m:set_speed(80)
  m:set_max_distance(math.random(16, 32))
  m:start(entity, function()
    sol.timer.start(entity, math.random(500, 3000), function()
      entity:start_dragonfly_movement()
    end)
  end)
  function m:on_obstacle_reached()
    m:stop()
    sol.timer.start(entity, math.random(500, 3000), function()
      entity:start_dragonfly_movement()
    end)
  end
end


function entity:on_interaction()
  entity:remove()
  if game:has_item(entity.treasure:get_name()) then
    entity.treasure:add_amount(1)
    sol.audio.play_sound"treasure_short"
  else
    --first time acquiring this material
    hero:start_treasure(entity.treasure:get_name())
  end
end
