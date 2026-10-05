local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_magnet_gauntlet")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  local slot_assigned = (props and props.slot_assigned) or (game:get_item_assigned(1) == item and 1 or 2)
  local mag_state = item:get_magnet_state()

  item.positive_polarity = not item.positive_polarity
  hero:start_state(mag_state)

  print"Magnets are happening. This isn't finished"

  sol.timer.start(hero,10,function()
    if game:is_command_pressed("item_" .. slot_assigned) then
      return true
    else
      mag_state:set_can_control_direction(true)
      sol.timer.start(hero, 200, function() --give a tiny buffer to face a different direction before falling.
        hero:unfreeze()
        item:set_finished()
      end)
    end
  end)

end


function item:get_magnet_state()
  local state = sol.state.create("magnet")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("lava", true)
  state:set_affected_by_ground("hole", false)
  state:set_affected_by_ground("deep_water", false)
  state:set_affected_by_ground("lava", false)
  state:set_gravity_enabled(false)
  state:set_can_come_from_bad_ground(false)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(true)
  state:set_can_use_switch(false)
  state:set_can_use_stream(false)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")

  return state
end
