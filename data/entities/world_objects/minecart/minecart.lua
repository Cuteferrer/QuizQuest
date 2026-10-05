local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local DEFAULT_SPEED = 180

function entity:on_created()
  entity:set_traversable_by(false)
  --entity:set_can_traverse(true)
  entity:set_can_traverse("enemy", true)
  entity:set_can_traverse("separator", true)
  entity:set_drawn_in_y_order(true)
  entity:set_property("unstable_floor", "true")
  entity:set_modified_ground("traversable")
  entity.is_track_vehicle = true
  entity.speed = tonumber(entity:get_property("speed") or DEFAULT_SPEED)
  entity.hookshot_target = true

  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)

  --Set origin position so it can move back on a map reset:
  entity.home_x, entity.home_y, entity.home_z = entity:get_position()
  map:register_checkpoint_callback(entity, function()
    entity:set_position(entity.home_x, entity.home_y, entity.home_z)
  end)

  --Interaction icon:
  entity.show_interact_icon = function(hero)
    return not hero:overlaps(entity)
  end

  entity:set_traversable_by("custom_entity", function(entity, other)
    local model = other:get_model()
    local is_moving = entity:is_moving()
    if model:match("projectile") and is_moving then
      return true
    elseif model:match("arrow_player") and is_moving then
      return true
    end
  end)

  --Smash into things:
  entity:add_collision_test("sprite", function(entity, other)
    local m = entity:get_movement()
    if entity:is_moving() and other.react_to_minecart_smash then
      other:react_to_minecart_smash(entity)
    end
  end)

  --Take on an enemy as passenger if they overlap at the start of the map
  sol.timer.start(entity, 10, function()
    for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
      if e:get_type() == "enemy" then
        e:set_position(e:get_position())
        entity:set_passenger(e)
        e:get_sprite():set_xy(0, -8)
      end
    end
  end)

end


function entity:is_moving()
  local m = entity:get_movement()
  return m and (m:get_speed() > 0)
end


function entity:get_passenger()
  return entity.passenger
end


function entity:set_passenger(passenger)
  entity.passenger = passenger
end


function entity:stop()
  entity:get_sprite():set_animation("stopped")
  local m = entity:get_movement()
  if m then m:stop() end
end


function entity:reverse()
  local m = entity:get_movement()
  if m then
    m:stop()
    local angle = m:get_angle()
    m:set_angle(angle + (math.pi) % (math.pi * 2))
    m:start(entity)
  end
end


function entity:stop_and_reverse()
  entity:get_sprite():set_animation("stopped")
  local m = entity:get_movement()
  if m then
    m:stop()
    entity:set_direction((entity:get_direction() + 2) % 4)
  end
end


function entity:hit_stopper()
  local m = entity:get_movement()
  if (not m) or (m:get_speed() == 0) then return end --do nothing if the cart wasn't moving

  local passenger = entity:get_passenger()
  local dir = m:get_direction4()
  sol.audio.play_sound("running_obstacle")
  entity:stop_and_reverse()

  if passenger then --Fling hero off
    if passenger:get_type() == "hero" then
      entity:yeet_hero(passenger, dir)
    end
  end
end


function entity:on_interaction()
  local hero = map:get_hero()
  entity:board(hero)
end


function entity:board(hero)
  local previous_passenger = entity:get_passenger()
  if previous_passenger and previous_passenger:exists() then --someone already in the cart
    return
  elseif previous_passenger then --someone was in the cart, but they don't exist anymore, clear them out
    previous_passenger = nil
    entity:set_passenger(nil)
  end
  local hero_sprite = hero:get_sprite()
  hero:freeze()
  sol.audio.play_sound"jump"
  hero:set_animation("jumping")
  hero_sprite:set_xy(0, -8)
  local m = sol.movement.create"target"
  m:set_target(entity)
  m:set_ignore_obstacles(true)
  m:set_speed(100)
  m:start(hero, function()
    hero:set_animation("stopped")
    hero:unfreeze()
    entity:set_passenger(hero)
    entity:start_rolling()
    --Minecart door visual:
    hero.minecart_door_sprite = hero:create_sprite("world_objects/minecart/door")
  end)

end


function entity:yeet_hero(hero, direction)
  entity:set_passenger(nil)
  local hero_sprite = hero:get_sprite()
  hero:set_animation("jumping")
  hero:stop_solforge_attack()
  hero:freeze()
  hero:set_direction(direction)
  --Minecart door visual:
  hero:remove_sprite(hero.minecart_door_sprite)
  local m = sol.movement.create"straight"
  m:set_ignore_obstacles(true)
  m:set_max_distance(32)
  m:set_speed(200)
  m:set_angle(direction * math.pi / 2)
  m:start(hero, function()
    hero_sprite:set_xy(0,0)
    hero:unfreeze()
    hero:set_animation("stopped")
  end)
end


function entity:start_rolling()
  local passenger = entity:get_passenger()
  entity:get_sprite():set_animation("moving")
  local dir = entity:get_direction()
  local is_obstacle = entity:test_obstacles(game:dx(8)[dir], game:dy(8)[dir])
  if is_obstacle then dir = (dir + 2) % 4 end
  local m = sol.movement.create("straight")
  m:set_angle(math.pi / 2 * dir)
  m:set_speed(entity.speed)
  m:set_smooth(false)
  --m:set_ignore_obstacles(true) -- if generally, it'd be better for the cart to blow through anything than get knocked off track. This is taken care of by the reverse when bumping
  m:start(entity)

  function m:on_position_changed()
    local x, y, z = entity:get_position()
    if passenger then
      --Don't move if overlapping a separator:
      if passenger.crossing_separator then return end

      passenger:set_position(x, y+1, z)
      --Minecart door visual:
      local sdir = passenger.minecart_door_sprite:get_direction()
      local edir = entity:get_direction()
      if sdir ~= edir then
        passenger.minecart_door_sprite:set_direction(edir)
      end
    end
  end

  --Destroy minecart if it hits an obstacle, rather than making the hero stuck forever:
  --[[
  function m:on_obstacle_reached()
    --Minecart door visual:
    if passenger.minecart_door_sprite then passenger:remove_sprite(passenger.minecart_door_sprite) end
    entity:set_passenger(nil)
    entity:remove()
    local x, y, z = entity:get_position()
    local crash_effect = map:create_custom_entity{
      x=x, y=y, layer=z, width=16, height=16, direction=0,
      sprite = "destructibles/barrel",
      model = "ephemeral_effect",
    }
    crash_effect:get_sprite():set_animation("destroy")
    sol.audio.play_sound("breaking_crate")
  end
  --]]

  --Reverse minecart if it hits an obstacle:
  function m:on_obstacle_reached()
    sol.audio.play_sound("running_obstacle")
    sol.audio.play_sound("impact_metal")
    entity:reverse()
  end

  local cart_wheel_counter = 1
  sol.timer.start(entity, 0, function()
    if entity:is_moving() then
      local sfx = sol.sound.create("minecart_wheels_" .. cart_wheel_counter)
      sfx:set_pitch(math.random(90, 110) / 100)
      sfx:set_volume(60)
      sfx:play()
      cart_wheel_counter = cart_wheel_counter + 1
      if cart_wheel_counter > 3 then cart_wheel_counter = 1 end
      return 600
    end
  end)
end


--JANK:
--This quickly activates a flag when the hero crosses a separator.
--This prevents a visual bug where the minecart and separator both try to move the hero, moving him back and forth across a separator threshold,
--making the camera track back and forth weirdly
--I don't like this solution, but it does work
local sep_meta = sol.main.get_metatable"separator"
sep_meta:register_event("on_activating", function(sep)
  local hero = game:get_hero()
  hero.crossing_separator = true
  sol.timer.start(hero, 100, function()
    hero.crossing_separator = nil
  end)
end)


