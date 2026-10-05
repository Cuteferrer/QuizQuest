local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  local map_id = map:get_id():gsub("/", "_")
  local x, y, z = entity:get_position()
  entity.savegame_id = map_id .. "_treasure_glow_" .. x .. "_" .. y .. "_" .. z
  entity.treasure = entity:get_property("treasure")

  if pcall(function() game:get_item(entity.treasure) end) then
  else
    error("Error: no such item '" .. entity.treasure .. "' found for item_glow entity at " .. x .. ", " .. y .. ", " .. z)
  end

  if game:get_value(entity.savegame_id) then
    entity:remove()
  end

  entity:set_drawn_in_y_order(true)
  --entity:set_traversable_by("enemy", false)
  entity:set_traversable_by("hero", function(entity, other) return entity:overlaps(other) end)
  map:register_light_source(entity, "candle")
end

function entity:on_interaction()
  local hero = map:get_hero()
  entity:remove()
  sol.audio.play_sound("treasure_short")
  local variant = tonumber(entity:get_property("variant")) or 1
  --hero:start_treasure(entity.treasure, variant)
  local item = game:get_item(entity.treasure)
  item:set_variant(variant)
  if item.on_obtaining then item:on_obtaining(variant) end
  if item.on_obtained then item:on_obtained(variant) end
  sol.timer.start(game, 10, function() --Delay by 10ms so the input from interacting with the item doesn't close popup menu
    item:show_popup(variant)
  end)

  game:set_value(entity.savegame_id, true)
end
