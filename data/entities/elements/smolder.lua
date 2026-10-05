local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  entity:set_size(16,16)
  entity:set_drawn_in_y_order(true)
  entity:set_follow_streams(true)
  map:register_light_source(entity, "candle")
  local burn_duration = entity:get_property("burn_duration") or 1000

  if not entity:get_sprite() then
    sprite = entity:create_sprite("elements/smolder")
    sprite:set_animation("smolder")
  end

  --Interact with other entities
  map.burned_entities = map.burned_entities or {}

  local start_burning_delay = 1500
  entity:add_collision_test("sprite", function(entity, other_entity, fire_sprite, other_entity_sprite)
    sol.timer.start(entity, start_burning_delay, function()
      if entity:overlaps(other_entity) and not map.burned_entities[other_entity] then
        if other_entity.react_to_fire then
          if other_entity.is_on_screen and not other_entity:is_on_screen() then
            return
          end
          other_entity:react_to_fire(entity)
        elseif other_entity.can_burn or other_entity:get_property("can_burn") then
          sol.timer.start(entity, 500, function()
            local x, y, z = other_entity:get_position()
            other_entity:remove()
            map:propagate_fire(x, y, z)
          end)
        elseif other_entity:get_type() == "hero" then
          other_entity:start_hurt(entity, game:get_value"fire_damage" or 1)
        end
      end
      --prevent a billion collisions
      map.burned_entities[other_entity] = true
      sol.timer.start(map, 1000, function() map.burned_entities[other_entity] = false end)
    end)
  end)


end
