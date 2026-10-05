--An ice attack that calls entity:react_to_ice() when it collides with something.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite
local duration = 500

function entity:on_created()
  sprite = entity:create_sprite("elements/ice_blast")
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)

  local collided_entities = {}

  entity:add_collision_test("sprite", function(entity, other_entity)
    if collided_entities[other_entity] then return end
    if other_entity:get_type() == "hero" then return end
    collided_entities[other_entity] = other_entity
    if other_entity.react_to_ice then
      other_entity:react_to_ice(entity)
    end

    sol.timer.start(entity, duration, function()
      sprite:set_animation("disappear", function()
        entity:remove()
      end)
    end)
  end)

  --Different collision test for hero
  entity:add_collision_test("overlapping", function(entity, other_entity)
    if other_entity:get_type() == "hero" and other_entity.react_to_ice and not entity.harmless_to_hero then
      other_entity:react_to_ice()
    end
  end)

end

function entity:set_duration(d)
  duration = d
  sol.timer.start(entity, duration, function()
    sprite:set_animation("disappear", function()
      entity:remove()
    end)
  end)
end
