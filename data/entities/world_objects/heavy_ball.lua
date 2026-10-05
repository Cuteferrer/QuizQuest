--[[
Created by Max Mraz, licensed MIT
A heavy object - can be lifted if the hero's strength is "1", or >= entity property "weight"
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()


--Collision test to bump into things:
function entity:create_collider()
  local collided_entities = {}

  local x, y, z = entity:get_position()
  local w, h = entity:get_size()
  local collider = map:create_custom_entity{
    x=x, y=y, layer=z, width=w, height=h, direction=0,
    model = "ephemeral_effect",
    sprite = "entities/enemy_projectiles/debris_attack",
  }

  collider:add_collision_test("sprite", function(collider, other, sprite, other_sprite)
    if collided_entities[other] then return end
    collided_entities[other] = other
    sol.timer.start(map, 500, function() collided_entities[other] = nil end)

    if other.react_to_heavy_ball then
      other:react_to_heavy_ball(entity)

    elseif other:get_type() == "enemy" then
      local enemy = other
      if enemy.process_hit then
        enemy:process_hit({damage = entity.damage, damage_type = "physical", stagger_value = 50})
      else
        enemy:hurt(entity.damage)
      end
    end
  end)

  collider:add_collision_test("touching", function(entity, other)
    if collided_entities[other] then return end

    if other.react_to_heavy_ball then
      other:react_to_heavy_ball(entity)
    end
  end)

  collider:add_collision_test("overlapping", function(entity, other)
    if collided_entities[other] then return end

    if other.react_to_heavy_ball then
      other:react_to_heavy_ball(entity)
    end
  end)
end


function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_traversable_by("hero", entity.overlaps)
  entity:set_traversable_by("enemy", entity.overlaps)
  entity:set_drawn_in_y_order(true)
  entity:set_follow_streams(true)
  entity.weight = entity:get_property("weight") or 1
  entity:set_weight(entity.weight)
  entity.damage = entity:calculate_damage()

  --entity:create_collider()
  --clear collision tests after a few miliseconds so stopped balls don't damage enemies.
  --sol.timer.start(entity, 100, function() entity:clear_collision_tests() end)

  local ground = entity:get_ground_below()
  if ground == "hole" or ground == "lava" then
    entity:fall_down_hole() --trillium module
  elseif ground == "deep_water" then
    entity:fall_in_water()
  end

end


function entity:on_lifting(carrier, carried_object)
  carried_object:set_damage_on_enemies(entity.damage)
  carried_object:set_destruction_sound("running_obstacle")

  --Because the original entity no longer exists, we must create a new heavy_ball entity when the thrown object lands
  function carried_object:on_breaking()
    map:get_camera():shake({count = 3, amplitude = 5, speed = 80})
    local x, y, z = carried_object:get_position()
    local width, height = carried_object:get_size()
    local sprite = carried_object:get_sprite()
    local direction = sprite:get_direction()

    if carried_object:get_ground_below() == "wall" then y = y + 16 end
    local new_ball = carried_object:get_map():create_custom_entity({
      x = x, y = y, layer = z, width = width, height = height, direction = direction,
      sprite = sprite:get_animation_set(),
      model = "world_objects/heavy_ball",
    })
    new_ball:set_property("weight", entity:get_property("weight"))
    --Give new ball some collision:
    new_ball:create_collider()
  end

  --Fall into hole or water animation:
  function carried_object:on_removed()
    local ground = carried_object:get_ground_below()
    if ground == "hole" or ground == "lava" then
      carried_object.on_removed = nil --to prevent infinite loop
      carried_object:fall_down_hole() --trillium module
    elseif ground == "deep_water" then
      carried_object.on_removed = nil --to prevent infinite loop
      carried_object:fall_in_water()
    end
  end

end


function entity:calculate_damage()
  --You can write some function here to make the entity do different damage based on its sprite, or on the hero's strength, or something like this if you'd like
  --The big reason to have this function is that technically, the entity is totally recreated each time its thrown,
  --This function just makes it a little simpler to carry over damage to the new entity
  return entity:get_property("damage") or 4
end

