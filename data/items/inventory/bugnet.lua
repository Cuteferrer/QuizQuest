local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_bugnet")
  item:set_assignable(true)
end

function item:on_using()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  local net = map:create_custom_entity{
    x = x, y = y, layer = z, width = 16, height = 16, direction = direction,
    sprite = "entities/bugnet",
  }
  --Remove the item if the player is hit, so it doesn't keep animating on its own
  hero:register_event("on_taking_damage", function()
    net:remove()
  end)
  net:add_collision_test("sprite", function(net, other_entity)
    if (other_entity:get_type() == "custom_entity") and (other_entity:get_model() == "animals/bug") then
      local bug = other_entity
      local treasure, treasure_name, variant = bug.treasure, bug.treasure:get_name(), bug.treasure_variant
      bug:remove()
      if game:has_item(treasure_name) then
        sol.audio.play_sound"treasure_short"
        treasure:add_amount(1)
      else
        net:remove()
        hero:start_treasure(treasure_name, variant)
      end
    end
  end)
  hero:set_animation("sword", function()
    if net:exists() then net:remove() end
    item:set_finished()
  end)
end

