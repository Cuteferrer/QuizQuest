--An entity that can freeze water, create a block of ice, or cause entity:react_to_ice() when colliding with entities.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  sprite = entity:create_sprite("elements/ice_sparkle")
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  sprite:set_animation("sparkle", function() entity:remove() end)

  local collided_entities = {}

  entity:add_collision_test("sprite", function(entity, other_entity)
    if collided_entities[other_entity] then return end
    collided_entities[other_entity] = other_entity
    if other_entity.react_to_ice then
      if (other_entity:get_type() == "hero") and entity.harmless_to_hero then return end
      other_entity:react_to_ice(entity)
    end
  end)

  if entity:get_ground_below() == "shallow_water" or entity:get_ground_below() == "deep_water" then
    map:create_ice_platform(entity:get_position())

  elseif entity:get_ground_below() == "traversable" or entity:get_ground_below() == "grass" then
    map:create_ice_block(entity:get_position())
  end

end
