local item = ...
local game = item:get_game()

local heal_amount = 8
local magic_cost = 50
local speed_delta = 50

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_hush")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  hero:set_animation("kneeling")
  local x, y, z = hero:get_position()
  --[[portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,150,100} --]]
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100}

  sol.timer.start(hero, 1000, function()
    light_effect_entity:remove()
    hero:start_state(item:get_stealth_state())
  end)
end)


function item:get_stealth_state()
  local hero = game:get_hero()
  local state = sol.state.create("stealth_spell")
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
      hero:set_animation"walking"
    else
      hero:set_animation"stopped"
    end
  end
  function state:on_started()
    hero.stealth_mode = true
    hero:get_sprite():set_opacity(100)
    hero:set_walking_speed(hero:get_walking_speed() - speed_delta)
  end

  function state:on_finished()
    hero.stealth_mode = false
    hero:get_sprite():set_opacity(255)
    hero:set_walking_speed(hero:get_walking_speed() + speed_delta)
  end

  function state:on_command_pressed(cmd)
    local handled = false
    if cmd == "attack" then
      hero:unfreeze()
      handled = true
    elseif cmd == "action" then
      hero:unfreeze()
      handled = false
    end
    return handled
  end

  return state
end

