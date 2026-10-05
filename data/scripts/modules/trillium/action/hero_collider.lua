--[[
Created by Max Mraz, licensed MIT
Creates a collider for the hero that may interact with various things
Can be used for some entities that interact with the hero, rather than giving each of THEM a collision test
--]]

local hero_meta = sol.main.get_metatable"hero"
local map_meta = sol.main.get_metatable"map"

map_meta:register_event("on_started", function(map)
  local hero = map:get_hero()
  local x, y, z = hero:get_position()

  local collider = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = "hero/collider_square_small",
  }
  collider:set_visible(false)

  --Sprite collisions:
  collider:add_collision_test("sprite", function(collider, entity)
    if entity:get_layer() ~= collider:get_layer() then return end --must be on same layer
    --for custom entities:
    if entity:get_type() == "custom_entity" then
      local model = entity:get_model()
      --Foliage: rustle:
      if model == "environment/foliage" then
        entity:rustle(hero)
      end
    end
  end)


  hero:register_event("on_position_changed", function(hero, x, y, z)
    collider:set_position(x, y, z)
  end)

end)


