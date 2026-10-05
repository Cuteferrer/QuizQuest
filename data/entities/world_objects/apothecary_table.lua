local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite


function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity:set_size(32, 24)
  entity:set_origin(16, 21)
  sprite = entity:get_sprite()

  sol.timer.start(entity, 3000, function()
    sprite:set_animation("flashing", function()
      sprite:set_animation"stopped"
    end)
    return true
  end)
end


function entity:on_interaction()
  sol.timer.start(map, 10, function()
    game:start_crafting()
  end)
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
