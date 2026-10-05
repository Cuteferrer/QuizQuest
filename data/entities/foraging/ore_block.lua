local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

--table contains items from "items/materials/mineral/[item_name]", and percentage chance of dropping
local drop_chance_percentage = {
  iron = 25,
  amber = 15,
  meteorite = 10,
  amethyst = 3,
  ruby = 2,
  sapphire = 2,
  emerald = 2,
  diamond = 1,
}

function entity:on_created()
  local sprite = entity:get_sprite() or entity:create_sprite("foraging_materials/mineral/ore_block")
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  entity.treasure_name = entity:get_property("treasure")
  if entity.treasure_name and sprite:has_animation(entity.treasure_name) then
    sprite:set_animation(treasure_name .. "ore")
  end
  sprite:set_direction(math.random(0, sprite:get_num_directions() - 1))
  entity.treasure_variant = entity:get_property"treasure_variant" or 1
  entity.hp = entity:get_property"hp" or 15

  --sparkle
  sol.timer.start(entity, math.random(1500, 2200), function()
    local sparkle = entity:create_sprite("entities/sparkle")
    sparkle:set_xy(math.random(-8, 8), math.random(-32, -8))
    sol.timer.start(entity, 500, function()
      entity:remove_sprite(sparkle)
    end)
    return true
  end)

  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    if other_entity:get_type() == "explosion" then
      entity:shatter()
    end
  end)
end

function entity:react_to_solforge_weapon(weapon)
  if not entity.shattered then
    local attack_power = game:get_value(weapon.item_id .. "_attack_power")
    entity.hp = entity.hp - attack_power
    local debris_sprite = entity:create_sprite("foraging_materials/mineral/ore_block")
    debris_sprite:set_animation("debris", function() entity:remove_sprite(debris_sprite) end)
    debris_sprite:set_direction(math.random(0, 3))
    if entity.hp <= 0 then
      entity:shatter()
    end
  end
end

function entity:react_to_drillspear()
  entity:shatter()
end

function entity:shatter()
  if entity.shattered then return end
  entity.shattered = true
  local x, y, z = entity:get_position()
  if entity.treasure_name then
    --specific item specified in entity properties
    map:create_pickable{
      x=x, y=y, layer=z,
      treasure_name = entity.treasure_name,
      treasure_variant = entity.treasure_variant,
    }
  else
    --no treasure specified, generate random
    random_treasure = entity:get_random_treasure()
    map:create_pickable{
      x=x, y=y, layer=z,
      treasure_name =random_treasure,
      treasure_variant = entity.treasure_variant,
    }
  end
  entity:get_sprite():set_animation("breaking", function()
    entity:remove()
  end)
end


function entity:get_random_treasure()
  local rand = math.random(1, 100)
  local drop = nil
  for drop_type, drop_percentage in pairs(drop_chance_percentage) do
    if rand <= drop_percentage then
      drop = "materials/mineral/" .. drop_type
      break
    else
      rand = rand - drop_percentage
    end
  end
  return drop
end

