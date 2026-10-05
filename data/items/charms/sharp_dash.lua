local item = ...
local game = item:get_game()

local damage = 4

function item:on_started()
  local savegame_variable = "possession_charm_sharp_dash"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3

  game.event_manager:subscribe("on_dashing", function()
    if game:is_charm_equipped(item:get_name()) then
      local hero = game:get_hero()
      local map = game:get_map()
      local x, y, z = hero:get_position()
      local direction = hero:get_direction()
      local movement = hero:get_movement()
      local attack_entity = map:create_custom_entity{
        x=x, y=y, layer=z, width=16, height=16, direction=direction,
        sprite = "items/sharp_dash",
      }
      movement:register_event("on_position_changed", function()
        local x, y, z = hero:get_position()
        attack_entity:set_position(x, y + 1, z)
      end)
      local attack_sprite = attack_entity:get_sprite()
      attack_sprite:set_opacity(50)
      function attack_sprite:on_animation_finished()
        attack_entity:remove()
      end

      attack_entity:set_drawn_in_y_order(true)
      local collided_entities = {}
      attack_entity:add_collision_test("sprite", function(attack_entity, other)
        if collided_entities[other] then return end
        collided_entities[other] = true
        if other:get_type() == "enemy" then
          if other.process_hit then
            other:process_hit(damage)
          else
            other:hurt(damage)
          end
        end
      end)
    end
  end)
end
