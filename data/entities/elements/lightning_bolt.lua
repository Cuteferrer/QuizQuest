local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  sprite = entity:create_sprite("elements/lightning_bolt")
  entity:set_drawn_in_y_order(true)

  sprite:set_animation("zap", function() entity:remove() end)
  map:register_light_source(entity, "light_xl")

  --Interact with other entities
  entity.lightning_affected_entities = entity.lightning_affected_entities or {}
  sol.timer.start(entity, 120, function() --slight delay before adding collision because it needs to come from the sky and hit the ground
    entity:add_collision_test("overlapping", function(entity, other_entity)
      --React to Lightning
      if other_entity.react_to_lightning_bolt and not entity.lightning_affected_entities[other_entity] then
        other_entity:react_to_lightning_bolt(entity)
      elseif other_entity.react_to_lightning and not entity.lightning_affected_entities[other_entity] then
        other_entity:react_to_lightning(entity)
      end


      --Conductive Entities
      if (not other_entity.electrified)
      and (other_entity.can_conduct_electricity or other_entity:get_property("can_conduct_electricity") ) then
        sol.timer.start(entity, 20, function()
          local x, y, z = other_entity:get_position()
          map:create_lightning_static{x=x, y=y, layer=z, source = "none"}
        end)
      end

      --only check this once per entity per unit of time
      entity.lightning_affected_entities[other_entity] = other_entity
      sol.timer.start(map, 800, function() entity.lightning_affected_entities[other_entity] = nil end)
    end)

    --Check if created in water- make a zap if so
    local x,y,z = entity:get_position()
    local ground = map:get_ground(x, y, z)
    if ground == "deep_water" or ground == "shallow_water" then
      map:create_lightning{x=x, y=y, layer=z, lightning_type"lightning_zap"}
    end
  end)

end

