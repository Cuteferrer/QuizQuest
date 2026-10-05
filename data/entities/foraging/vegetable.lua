local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity.treasure = game:get_item(entity:get_property("treasure"))
  entity.treasure_variant = entity:get_property"treasure_variant"

  --sparkle
  sol.timer.start(entity, math.random(1500, 2200), function()
    local sparkle = entity:create_sprite("entities/sparkle")
    sparkle:set_xy(math.random(-8, 8), math.random(-16, 0))
    sol.timer.start(entity, 500, function()
      entity:remove_sprite(sparkle)
    end)
    return true
  end)
end


function entity:on_interaction()
  entity:pick()
end


function entity:react_to_solforge_weapon()
  local x, y, z = entity:get_position()
  entity:remove()
  local burst = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16,
    model = "ephemeral_effect",
    sprite = "foliage/bush_burst",
  }
  burst:set_drawn_in_y_order(true)
  map:create_pickable{
    x=x, y=y, layer=z,
    treasure_name = entity.treasure:get_name(),
    treasure_variant = entity.treasure_variant,
  }

end


function entity:pick()
  entity:remove()
  if game:has_item(entity.treasure:get_name()) then
    entity.treasure:add_amount(1)
    sol.audio.play_sound"treasure_short"
  else
    --first time acquiring this material
    hero:start_treasure(entity.treasure:get_name())
  end
end
