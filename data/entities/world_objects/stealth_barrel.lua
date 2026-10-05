local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local SPEED_DELTA = 50

function entity:on_created()
  entity:set_weight(0)
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity.on_interaction = true --hack to make "interact" prompt show up
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


function entity:on_lifting(hero, carried_object)
  sol.timer.start(hero, 500, function()
    hero:start_state(entity:get_state())
    local sprite = carried_object:get_sprite()
    sprite:set_animation("dropping", function()
    end)
  end)
end




function entity:get_state()
  local hero = map:get_hero()
  local state = sol.state.create("stealth_barrel")
  state:set_can_control_direction(true)
  state:set_can_control_movement(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(true)
  state:set_can_use_switch(true)
  state:set_can_use_stream(true)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("remove")

  function state:on_movement_changed(m)
    if m:get_speed() > 0 then
      hero:set_animation"stealth_barrel_walking"
    else
      hero:set_animation"stealth_barrel_stopped"
    end
  end

  function state:on_started()
    hero.stealth_mode = true
    hero:set_animation"stealth_barrel_stopped"
    hero:set_walking_speed(hero:get_walking_speed() - SPEED_DELTA)
  end

  function state:on_finished()
    hero.stealth_mode = false
    hero:set_walking_speed(hero:get_walking_speed() + SPEED_DELTA)
    local x, y, z = hero:get_position()
    local dummy_barrel = map:create_custom_entity{
      x=x, y=y+1, layer=z, width=16, height=16, direction=0,
      sprite="world_objects/stealth_barrel", model = "ephemeral_effect"
    }
    dummy_barrel:get_sprite():set_animation("shattering")
    sol.audio.play_sound"breaking_crate"
  end

  function state:on_command_pressed(cmd)
    if cmd == "attack" then
      hero:unfreeze()
    end
  end

  return state
end
