local map_meta = sol.main.get_metatable"map"

function map_meta:helicopter_cam()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()
  game.helicopter_cam = true
  game:get_hud():set_enabled(false)
  local state = sol.state.create()
  state:set_can_control_movement(true)
  state:set_visible(false)
  state:set_can_traverse(true)
  state:set_can_traverse_ground("wall", true)
  state:set_can_traverse_ground("low_wall", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("prickles", true)
  state:set_gravity_enabled(false)
  state:set_affected_by_ground("ladder", false)
  state:set_can_be_hurt(false)
  hero:start_state(state)
  hero:set_layer(map:get_max_layer())
  function state:on_joypad_button_pressed(button, joypad)
    if button == "b" or button == "left_shoulder" or button == "right_shoulder" then
      hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED)
      map:exit_helicopter_cam()
      hero:hole_drop_landing()
    end
  end
end

function map_meta:exit_helicopter_cam()
  local map = self
  local hero = map:get_hero()
  local game = map:get_game()
  game.helicopter_cam = false
  game:get_hud():set_enabled(true)
  hero:unfreeze()
end


function map_meta:kill_all_enemies()
  local map = self
  for e in map:get_entities_by_type"enemy" do
    if e.process_hit then
      e:process_hit{ damage = 999999 }
    end
  end
end


