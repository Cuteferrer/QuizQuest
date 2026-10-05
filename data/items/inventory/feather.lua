local item = ...
local game = item:get_game()

local SPEED_BOOST = 10
local JUMP_LENGTH = 450
local DOUBLE_JUMP_LENGTH = 460 --jump length 450 // double jump 650 allows jumping over 2 // 6

--Special note:
-- if game:get_value("feather_wind_shockwave") == true, then the feather will create a little gust of wind when you double jump that can damage enemies

function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  hero:start_feather_jump(JUMP_LENGTH)
  item:set_finished()
end



local hero_meta = sol.main.get_metatable("hero")

function hero_meta:start_feather_jump(jump_duration, jump_animation, prevent_double_jump)
  local hero = self
  local shadow_sprite
  local state = item:get_jumping_state()
  jump_animation = jump_animation or "jumping_2"

  function state:on_started()
    hero:set_walking_speed(hero:get_walking_speed() + SPEED_BOOST)
  end

  function state:on_finished()
    hero:remove_sprite(shadow_sprite)
    hero:set_walking_speed(hero:get_walking_speed() - SPEED_BOOST)
  end

  if hero.jump_timer then hero.jump_timer:stop() end
  hero:start_state(state)
  hero.jump_timer = sol.timer.start(hero, jump_duration, function()
    hero:set_animation"stopped"
    hero:unfreeze()
  end)
  hero:set_animation(jump_animation)
  shadow_sprite = hero:create_sprite("shadows/shadow_medium")
  sol.audio.play_sound"jump"


  function state:on_command_pressed(cmd)
    local handled = false
    local slot_assigned = (game:get_item_assigned(1) and (game:get_item_assigned(1):get_name() == item:get_name()) ) and 1 or 2
    if cmd == "item_" .. slot_assigned and (item:get_variant() >= 2) and not prevent_double_jump then
      local map = game:get_map()
      local hero = map:get_hero()
      local direction = hero:get_direction()
      local wing_sprite = hero:create_sprite"items/double_jump_wings"
      wing_sprite:set_direction(hero:get_direction())
      wing_sprite:set_animation("jumping", function() hero:remove_sprite(wing_sprite) end)
      sol.timer.start(map, 100, function()
        if game:get_value"feather_wind_shockwave" then item:generate_shockwave() end
      end)
      hero:start_feather_jump(DOUBLE_JUMP_LENGTH, "double_jumping", true)

    --dive shockwave
    elseif cmd == "attack" and game:get_value("jumping_shockwave_dive") then
      local map = game:get_map()
      local hero = map:get_hero()
      hero.jump_timer:stop()
      hero:set_direction(3)
      hero:freeze()
      hero:set_animation("double_jumping", function()
      end)
      sol.timer.start(hero, 200, function()
        hero:set_animation("landing_short", function()
          hero:unfreeze()
        end)
        item:generate_shockwave()
        sol.audio.play_sound"running_obstacle"
      end)
      handled = true
    end
    return handled
  end

end



function item:get_jumping_state()
  local state = sol.state.create("feather_jumping")
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("lava", true)
  state:set_affected_by_ground("hole", false)
  state:set_affected_by_ground("deep_water", false)
  state:set_affected_by_ground("lava", false)
  state:set_gravity_enabled(false)
  state:set_can_come_from_bad_ground(false)
  state:set_can_be_hurt(false)
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


function item:generate_shockwave(big)
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local sprite_id = big and "enemies/trillium_enemies/shockwave_8x7" or "items/wind_shockwave"
  local shockwave = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16, sprite=sprite_id, model="damaging_entity",
  }
  shockwave:get_sprite():set_opacity(100)
  shockwave:get_sprite():set_scale(1.5, 1.5)
end
