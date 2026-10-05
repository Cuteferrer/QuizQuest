sol.modules.get_object("multi_events")
local game_meta = sol.main.get_metatable"game"
local hero_meta = sol.main.get_metatable"hero"
local map_meta = sol.main.get_metatable"map"



function process_command_pressed(command, state)
  local handled = false
  local game = sol.main.get_game()

  if game:is_suspended() then --don't process anything if the game is suspended (menu commands should be handled a different way)
    handled = false

  elseif command == "attack" and state == "aiming" then
    --Let the aiming state handle the attack command itself to charge the Dead Man's Shot
    handled = false

  elseif command == "attack" then
    game:queue_command_until_free"attack"
    handled = true

  elseif command == "aim" then
    game:queue_command_until_free("aim", 500)
    handled = true
  --Note: "fire" while aiming is handled by the aim state

  elseif command == "hookshot" and state == "free" and game:get_value("can_use_hookshot") then
    if game:get_map():get_entity("hookshot_hook_entity") then
      return
    end
    game:get_item("inventory/hookshot"):on_using()
    handled = true

  elseif command == "dodge" then
    game:queue_command_until_free"dodge"
    handled = true

  --Item Quickswaps:
  elseif command == "quickswap_melee" then
    game:quickswap"melee"
    handled = true
  elseif command == "quickswap_gun" then
    game:quickswap"gun"
    handled = true
  elseif command == "quickswap_item_1" then
    game:quickswap"item_1"
    handled = true
  elseif command == "quickswap_item_2" then
    game:quickswap"item_2"
    handled = true

  --Pause:
  elseif command == "map" and game:is_pause_allowed() then
    handled = true
    sol.controls.get_main_controls():simulate_pressed("pause")
    local pause_menu = game:get_pause_menu()
    pause_menu:start_map_override()
  end

  return handled
end


game_meta:register_event("on_started", function(game)

  --Local command functions---------------------------------------------
  local function on_command_pressed(command)
    local hero = game:get_hero()
    local state, state_ob = hero:get_state()
    local handled = false
    --Pass along command input to custom states, which won't pick up custom commands themselves in 1.6:
    if sol.main.old_controls_version and state == "custom" then
      if state_ob.on_command_pressed then
        state_ob:on_command_pressed(command)
      end
    end

    if state == "custom" then state = state_ob:get_description() end --Translate custom states to their description for convenience

    handled = process_command_pressed(command, state)

    return handled
  end


  function on_command_released(command)
    local hero = game:get_hero()
    --Pass along command input to custom states, which won't pick up custom commands themselves
    local state, state_ob = hero:get_state()
    if sol.main.old_controls_version and state == "custom" then
      if state_ob.on_command_released then
        state_ob:on_command_released(command)
      end
    end

  end


  --Hook game into local command functions -----------------------------------------------
  game:register_event("on_command_pressed", function(self, command)
    return on_command_pressed(command)
  end)

  game:register_event("on_command_released", function(self, command)
    return on_command_released(command)
  end)


  --Mouse commands are currently hardcoded. They simulate press/release on the controls object, instead of actually being bound:
  function game:on_mouse_pressed(button, x, y)
    local hero = game:get_hero()
    local state_ob = hero:get_state_object()
    local is_aiming = state_ob and state_ob:get_description() == "aiming"
    local handled = false

    --Right click, aim:
    if button == "right" then
      sol.controls.get_main_controls():simulate_pressed("aim")
      game.mouse_aiming = true
      handled = true

    --Left click, attack (or fire):
    elseif button == "left" and is_aiming then
      sol.controls.get_main_controls():simulate_pressed("fire")
      handled = true

    elseif button == "left" and not is_aiming then
      sol.controls.get_main_controls():simulate_pressed("attack")
      handled = true

    --Secret third button
    --Hookshot:
    elseif ((button == "middle") or (button == "x1") or (button == "x2")) and not is_aiming and game:get_value("can_use_hookshot") then
      sol.controls.get_main_controls():simulate_pressed("hookshot")
      handled = true

    end

    -- return handled
  end


  function game:on_mouse_released(button, x, y)
    local hero = game:get_hero()
    local state_ob = hero:get_state_object()
    local is_aiming = state_ob and state_ob:get_description() == "aiming"
    local handled = false

    if button == "right" then
      game.mouse_aiming = false
      sol.controls.get_main_controls():simulate_released("aim")

    elseif button == "left" and is_aiming then
      sol.controls.get_main_controls():simulate_released("fire")

    elseif button == "left" then
      sol.controls.get_main_controls():simulate_released("attack")

    end

    return handled
  end



  local function check_if_still_holding_aim()
    local still_aiming = false
    if not game:get_value("equipped_gun") then return false end --cancel if we don't have a gun equipped
    if sol.controls.get_main_controls():is_pressed("aim") or sol.input.is_mouse_button_pressed("right") then
      still_aiming = true
    end
    return still_aiming
  end


  local function overlaps_stairs(hero)
    local map = hero:get_map()
    local overlaps = false
    for e in map:get_entities_in_rectangle(hero:get_bounding_box()) do
      if e:get_type() == "stairs" then
        overlaps = true
        break
      end
    end
    return overlaps
  end


  local function check_can_do_command(command)
    local hero = game:get_hero()
    local map = hero:get_map()
    local state, state_ob = hero:get_state()
    if state_ob then state = state_ob:get_description() end --If we've a state object, then the state is just "custom" which isn't super useful.
    local can_do = false
    if map:is_opening_transition() then
      can_do = false
    elseif state == "free" and not overlaps_stairs(hero) then
      can_do = true
    elseif command == "dodge" and game:is_suspended() then
      can_do = false
    elseif state == "aiming" and command == "dodge" then
      can_do = true
    elseif state == "sprinting" and command == "attack" then
      can_do = true
    end
    return can_do
  end


  function game:queue_command_until_free(command, lifespan)
    lifespan = lifespan or 300 --length in which a command can sit in the queue
    local hero = game:get_hero()
    local hero_state, state_object = hero:get_state()
    if check_can_do_command(command) then
      game:do_queued_command(command)
    elseif command == "attack" and state_object and state_object:get_description() == "aiming" then
      --hack to prevent attack from queuing when pressing the fire/attack button guns. Otherwise, you use your queued attack when you stop aiming.
      return
    else
      if game.queued_command_timer then game.queued_command_timer:stop() end
      local queue_lifetime = 0
      game.queued_command_timer = sol.timer.start(game, 10, function()
        queue_lifetime = queue_lifetime + 10
        if check_can_do_command(command) then
          game:do_queued_command(command)
        elseif queue_lifetime < lifespan then
          return true
        end
      end)
    end
  end


  function game:clear_queued_commands()
    if game.queued_command_timer then game.queued_command_timer:stop() end
  end


  hero_meta:register_event("on_state_changing", function(hero, current, next)
    if current == "back to solid ground" then
      game:clear_queued_commands()
    end
  end)


  map_meta:register_event("on_started", function()
    game:clear_queued_commands()
  end)

  map_meta:register_event("on_opening_transition_finished", function()
    game:clear_queued_commands()
  end)


  function game:do_queued_command(command)
    local hero = game:get_hero()
    local state, state_object = hero:get_state()
    if state_object then state = state_object:get_description() end

    if command == "dodge" and hero:get_controlling_stream() == nil then
      hero:dash()
      handled = true

    elseif command == "attack" then
      hero:set_direction(game:get_direction_held() / 2)
      local weapon_id = game:get_value("equipped_weapon")
      if weapon_id == nil then return end --cancel if we don't have a weapon equipped
      local weapon = game:get_item(weapon_id)
      weapon:on_using()

    elseif command == "weapon_art" then
      hero:set_direction(game:get_direction_held() / 2)
      local weapon_id = game:get_value("equipped_weapon")
      if weapon_id == nil then return end --cancel if we don't have a weapon equipped
      local weapon = game:get_item(weapon_id)
      if weapon.weapon_art then
        weapon:weapon_art(hero)
      end

    elseif command == "aim" then --double check we still want to start aiming, could have let go of the command since it was queued:
      if check_if_still_holding_aim() then
        hero:start_aiming()
      end

    end
  end


  --Check if commands are being input when state changes (mostly just useful for things that should swap if the command has been held for a while and the hero just became free):
  hero_meta:register_event("on_state_changed", function(hero, state)
    if state == "free" then
      --Check if we've still got the aim button held, if so, start aiming
      if check_if_still_holding_aim() then hero:start_aiming() end

    end
  end)

  
end)


return menu