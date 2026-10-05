local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local save_id

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  --Check if we've already gotten this one
  local map_id = map:get_id():gsub("/", "_")
  local x, y, z = entity:get_position()
  save_id = map_id .. "_" .. x .. y .. z
  if game:get_value(save_id) then
    entity:remove()
  end

  --Change sprite for shallow water
  if map:get_ground(x, y, z) == "shallow_water" then
    entity:get_sprite():set_animation"shallow_water"
  end
end


function entity:release()
  local sprite = entity:get_sprite()
  local x, y, z = entity:get_position()
  sprite:set_animation("release", function()
    entity:remove()
  end)
  map:create_pickable({
    x = x, y = y, layer = z,
    treasure_name = "collectibles/soul_crystal",
    treasure_savegame_variable = save_id,
  })
end


function entity:on_interaction()
  entity:release()
end

function entity:react_to_solforge_weapon()
  entity:release()
end
