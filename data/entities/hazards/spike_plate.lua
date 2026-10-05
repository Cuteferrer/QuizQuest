local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

local base_damage = 20
local enemy_modifier = 3 --if you lure enemies into this I want it to be satisfying
local hero_modifier = 1.5 --actually it should do more damage to the hero also
local default_activation_time = 250 --how long between being stepped on and springing
local damage_frequency = 500
local active_damage_duration = 600


function entity:on_created()

  entity:set_tiled(true)
  entity:set_traversable_by(true)
  entity:set_property("unstable_floor", "true")
  entity.damage = entity:get_property("damage") or base_damage
  entity.activation_time = entity:get_property("activation_time") or default_activation_time
  entity.activation_sound = entity:get_property("activation_sound") or "trap_blade_2"
  entity.collided_entities = {}

  if entity:get_property("timed") or entity:get_property("frequency") then
    local frequency = entity:get_property("frequency")
    local offset = entity:get_property("offset") or 1000
    sol.timer.start(entity, offset, function()
      entity:make_sound(entity.activation_sound)
      entity.activated = true
      entity:activate()
      return frequency
    end)
  else
    entity:add_collision_test("overlapping", function(entity, other_entity)
      if not entity.activated then
        entity.activated = true
        entity:make_sound(entity.activation_sound)
        sol.timer.start(entity, entity.activation_time, function()
          entity:activate()
        end)
      end
    end)
  end

  entity:add_collision_test("overlapping", function(self, other_entity)
    if not entity.damage_active then return end

    if entity.collided_entities[other_entity] then return end
    entity.collided_entities[other_entity] = true
    sol.timer.start(entity, active_damage_duration, function()
      entity.collided_entities[other_entity] = nil
    end)

    --Damage hero:
    if other_entity:get_type() == "hero" and other_entity.process_hit then
      other_entity:process_hit{ damage = entity.damage * hero_modifier}
    elseif other_entity:get_type() == "hero" then
      other_entity:start_hurt(entity, entity.damage * hero_modifier)
    --Damage enemies:
    elseif other_entity:get_type() == "enemy" and other_entity.process_hit then
      other_entity:process_hit({damage = entity.damage * enemy_modifier})
    elseif other_entity:get_type() == "enemy" then
      other_entity:hurt(entity.damage * enemy_modifier)
    end
  end)

end

function entity:activate()
  entity.damage_active = true
  sol.timer.start(entity, active_damage_duration, function()
    entity.damage_active = false
  end)

  local sprite = entity:get_sprite()
  sprite:set_animation("activated", function()
    sprite:set_animation"set"
    entity.activated = false
  end)
end
