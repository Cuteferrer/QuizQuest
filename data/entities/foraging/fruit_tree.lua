local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by("hero", false)
  entity:set_traversable_by(false)

  --collision test for rolling:
  entity:add_collision_test("touching", function(entity, other)
    if other:get_type() == "hero" then
      local state, s_ob = other:get_state()
--print("Touching hero", state, s_ob and s_ob:get_description())
      if state == "custom" and s_ob:get_description() == "dashing" then
        entity:drop_fruit()
      end
    end
  end)

end


function entity:react_to_solforge_weapon()
  entity:drop_fruit()
end

function entity:react_to_explosion()
  entity:drop_fruit()
end



function entity:drop_fruit()
  if entity.hit_cooldown then return end
  entity.hit_cooldown = true
  sol.timer.start(entity, 200, function()
    entity.hit_cooldown = nil
  end)

  --Shake, play sound
  local sprite = entity:get_sprite()
  sol.audio.play_sound("impact_wood")
  sol.audio.play_sound("grass_rustling")
  sprite:set_animation("shaking", function()
    sprite:set_animation("shaking", function()
      sprite:set_animation("stopped")
    end)
  end)

  --Drop fruit if you already haven't:
  if entity.fruit_dropped then return end

  local radius = entity:get_property("radius") or 32
  local fruit_type = entity:get_property("fruit") or "materials/ingredients/apple"

  local num_dropped = math.random(1,3)
  local x, y, z = entity:get_position()

  for i = 1, num_dropped do
    local angle = math.rad(math.random(180,360))
    local dist = math.random(16, radius)
    local fruit = map:create_pickable({
      x = x + math.cos(angle) * dist,
      y = y - math.sin(angle) * dist,
      layer = z,
      direction = 0, width = 16, height = 16,
      treasure_name = fruit_type,
    })
  end

  entity.fruit_dropped = true
end

