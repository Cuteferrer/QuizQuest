local item = ...
local game = item:get_game()

local frequency = 60
local num_entities = 4

function item:on_started()
  local savegame_variable = "possession_charm_flamestep"
  item:set_savegame_variable(savegame_variable)
  item.charm_cost = 3

  game.event_manager:subscribe("on_dashing", function()
    if game:is_charm_equipped(item:get_name()) then
      local hero = game:get_hero()
      local map = game:get_map()
      local entities_created = 0
      sol.timer.start(hero, 0, function()
        local x, y, z = hero:get_position()
        local entity = map:create_fire{
          x=x, y=y, layer=z,
          properties = {{key = "burn_duration", value = 0,}}
        }
        entity.harmless_to_hero = true
        entities_created = entities_created + 1
        if entities_created < num_entities and hero:get_movement():get_speed() > 0 then
          return frequency
        end
      end)
    end
  end)
end
