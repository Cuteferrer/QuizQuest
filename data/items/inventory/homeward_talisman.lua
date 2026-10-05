local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_homeward_talisman")
  item:set_assignable(false)
end

function item:on_using()
  if not game:get_value"checkpoint_map" and not game:get_starting_location() then
    sol.audio.play_sound"wrong"
    item:set_finished()
    return
  end
  local hero = game:get_hero()
  local map = game:get_map()
  local light_effect_entity
  local portal_entity
  local charging_state = item:get_charging_state()
  function charging_state:on_finished()
    light_effect_entity:remove()
    portal_entity:remove()
  end
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  sol.audio.play_sound"world_warp"
  sol.timer.start(item, 80, function()
    hero:set_animation"charging"
    hero:start_state(charging_state)
  end)
  sol.timer.start(item, 1000, function()
    hero:set_animation("falling", function()
      hero:set_visible(false)
      game:start_flash()
      local homeward_map = game:get_value"checkpoint_map"
      local homeward_x = game:get_value"checkpoint_x"
      local homeward_y = game:get_value"checkpoint_y"
      local homeward_z = game:get_value"checkpoint_z"
      local backup_map, backup_destination = game:get_starting_location()
      hero:teleport(homeward_map or backup_map, backup_destination, "immediate")
      sol.timer.start(game, 40, function()
        if homeward_x and homeward_y and homeward_z then
          hero:set_position(homeward_x, homeward_y, homeward_z)
        end
        hero:set_direction(3)
        hero:set_visible(true)
        hero:set_animation"stopped"
        game:stop_flash()
        item:set_finished()
      end)
    end)
  end)
end


function item:get_charging_state()
  local state = sol.state.create("charging")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(false)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(false)
  state:set_can_use_stream(false)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")

  return state
end
