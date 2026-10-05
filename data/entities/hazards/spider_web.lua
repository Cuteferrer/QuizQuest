local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by("hero", true)
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  --Sticky collision
  entity:add_collision_test("overlapping", function(entity, other)
    if other:get_type() == "hero" then
      entity:web_hero(other)
    end
  end)
end


function entity:web_hero(hero)
  if hero:is_status_effect_active("webbed") then return end

  local sprite = entity:get_sprite()
  hero:freeze()
  hero:start_status_effect("webbed")
  local m = sol.movement.create"straight"
  m:set_angle(entity:get_angle(hero))
  m:set_speed(150)
  m:set_max_distance(16)
  m:start(hero)

  sprite:set_animation("shaking")
  sol.timer.start(entity, 500, function()
    sprite:set_animation("stopped")
  end)
end


function entity:react_to_fire()
  if entity.is_burning then return end
  entity.is_burning = true
  entity:clear_collision_tests()
  local sprite = entity:get_sprite()
  sprite:set_animation("burning", function()
    entity:remove()
  end)
end

