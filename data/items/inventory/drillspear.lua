local item = ...
local game = item:get_game()

local windup_duration = 200
local spin_duration = 500
local drillspear_damage = 6

function item:on_started()
  item:set_savegame_variable("possession_drillspear")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()
  local slot_assigned = (game:get_item_assigned(1) and (game:get_item_assigned(1):get_name() == item:get_name()) ) and 1 or 2
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()

  local drillspear = map:create_custom_entity{
    x=x, y=y, layer=z, direction=direction, width=16, height=16,
    sprite = "items/drillspear",
  }
  hero.drillspear = drillspear
  drillspear:set_drawn_in_y_order(true)
  drillspear:get_sprite():set_animation("windup")
  hero:set_animation"spear_windup"
  local state = item:get_drillspear_state()
  hero:start_state(state)
  function state:on_finished()
    drillspear:remove()
  end
  sol.timer.start(hero, windup_duration, function()
    hero:set_animation"drillspear"
    drillspear:get_sprite():set_animation"attack"
    drillspear.collided_entities = {}
    drillspear:add_collision_test("sprite", function(drillspear, other_entity)
      if other_entity.react_to_drillspear and not drillspear.collided_entities[other_entity] then
        drillspear.collided_entities[other_entity] = other_entity
        other_entity:react_to_drillspear()
      elseif other_entity:get_type() == "enemy" then
        other_entity:hurt(drillspear_damage)
      end
    end)
    function state:on_command_pressed(cmd)
      if cmd == "item_" .. slot_assigned and (item:get_variant() >= 2) and (item.jump_number == 1) then
        --item button pressed again
      end
    end
    sol.timer.start(hero, spin_duration, function()
      drillspear:remove()
      item:set_finished()
      hero:unfreeze()
    end)
  end)
end



function item:get_drillspear_state()
  local state = sol.state.create()
  state:set_description"drillspear"
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_use_sword(false)
  state:set_can_use_shield(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(true)
  state:set_can_use_stream(false)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")

  return state
end
