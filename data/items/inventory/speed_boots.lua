local item = ...
local game = item:get_game()

local SPEED_BOOST = 45

function item:on_started()
  item:set_savegame_variable("possession_speed_boots")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  local state = item:get_running_state()
  hero:start_state(state)
  item:set_finished()
end


function item:get_running_state()
  local hero = game:get_hero()
  local state = sol.state.create("speed_boot_running")
  state:set_can_use_item(false)
  state:set_affected_by_ground("shallow_water", true)

  function state:on_started()
    hero.speed_boots_running = true
    sol.audio.play_sound"running"
    hero:set_walking_speed(hero:get_walking_speed() + SPEED_BOOST)
  end

  function state:on_finished()
    sol.audio.play_sound"running"
    hero.speed_boots_running = false
    hero:set_walking_speed(hero:get_walking_speed() - SPEED_BOOST)
  end

  function state:on_movement_changed(m)
    if m:get_speed() and m:get_speed() > 0 then
      hero:set_animation"walking"
    else
      hero:set_animation"stopped"
    end
  end

  function state:on_command_pressed(cmd)
    if cmd ~= "up" and cmd ~= "down" and cmd ~= "right" and cmd ~= "left" then
      hero:unfreeze()
      return true
    end
  end

  return state
end


function item:generate_shockwave()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local shockwave = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16, sprite="items/wind_shockwave", model="damaging_entity",
  }
  shockwave:get_sprite():set_opacity(100)
end
