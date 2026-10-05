local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_traversable_by("hero", entity.overlaps)
  entity:set_traversable_by("enemy", entity.overlaps)
  entity:set_drawn_in_y_order(true)

end


function entity:on_interaction()
  entity:dispense()
end


function entity:dispense()
  if entity.ball and entity.ball:exists() then
    sol.audio.play_sound"wrong"
    return
  end
  entity:make_sound("stone")
  local x, y, z = entity:get_position()
  local ball = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    model = "world_objects/heavy_ball",
    sprite = "world_objects/heavy_ball",
  }
  entity.ball = ball
  local m = sol.movement.create"straight"
  m:set_ignore_obstacles(true)
  m:set_angle(3 * math.pi / 2)
  m:set_speed(120)
  m:set_max_distance(8)
  m:start(ball, function()
    map:screenshake()
    entity:make_sound("running_obstacle")
  end)
end

