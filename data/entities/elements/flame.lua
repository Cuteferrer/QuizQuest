local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  entity:set_size(16,16)
  entity:set_drawn_in_y_order(true)
  entity:set_follow_streams(true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity.burn_duration = entity:get_property("burn_duration") or 1000

  --Animate, then burn out
  sprite = entity:create_sprite("elements/fire")
  sprite:set_animation("fire")
  sol.timer.start(entity,10,function()
    sol.timer.start(entity, entity.burn_duration, function()
      entity:get_sprite():set_animation("fire_" .. math.random(1,2), function()
        entity:remove()
      end)
    end)
  end)
  local extra_hitbox_sprite = entity:create_sprite("elements/fire")
  extra_hitbox_sprite:set_animation("hitbox_burst")
  extra_hitbox_sprite:set_opacity(5)

  --Interact with other entities
  entity.burned_entities = {}

  entity:add_collision_test("sprite", function(entity, other_entity, fire_sprite, other_entity_sprite)
    --only check this once per entity
    if entity.burned_entities[other_entity] then return end
    entity.burned_entities[other_entity] = true
    sol.timer.start(map, entity.burn_frequency or 600, function() entity.burned_entities[other_entity] = false end)
    --hero collides based on overlapping collision, not sprite collision
    if other_entity:get_type() == "hero" then return end
    if other_entity.react_to_fire then
      other_entity:react_to_fire(entity)

    elseif other_entity.can_burn or other_entity:get_property("can_burn") then
      other_entity.can_burn = nil
      other_entity:set_property("can_burn", nil)
      sol.timer.start(entity, 500, function()
        local x, y, z = other_entity:get_position()
        other_entity:remove()
        map:propagate_fire(x, y, z)
      end)
    end
  end)


  --Special collision with hero for damage
  sol.timer.start(entity, 10, function()
    entity:add_collision_test("overlapping", function(entity, other_entity)
      if entity.burned_entities[other_entity] then return end
      if other_entity:get_type() == "hero" and not other_entity:is_blinking() and not entity.harmless_to_hero then
        if other_entity.react_to_fire then other_entity:react_to_fire(entity)
        else other_entity:start_hurt(entity, (game:get_value"fire_damage" or 1)) end
      end
    end)
  end)

  --Be a light source:
  map:register_light_source(entity, "torch")

end
