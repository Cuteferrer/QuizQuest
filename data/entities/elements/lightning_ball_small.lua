--Small entity whose only purpose is to create a lightning zap when it collides with something else.
--Useful as a projectile that explodes into lightning on contact.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  entity:set_size(16,16)
  entity:set_drawn_in_y_order(true)
  entity:set_follow_streams(false)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("low_wall", true)
  map:register_light_source(entity, "torch")

  --entity:set_can_traverse("enemy", false)

  sprite = entity:create_sprite("elements/lightning_ball_small")


  sol.timer.start(entity, 50, function()
    if not entity:get_movement() then entity:remove() end
    local m = entity:get_movement()
    function m:on_obstacle_reached()
      local x,y,z = entity:get_position()
      map:create_lightning{x=x, y=y, layer=z, lightning_type="lightning_zap"}
      entity:remove()
    end
  end)

end

