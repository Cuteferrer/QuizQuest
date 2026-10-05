local hero_meta = sol.main.get_metatable"hero"

--Fire
function hero_meta:react_to_fire(fire)
  if fire.harmless_to_hero then return end
  local hero = self
  local game = hero:get_game()
  local state, state_ob = hero:get_state()
  if state == "custom" then state = state_ob:get_description() end

  if hero:is_blinking() then return end
  if state == "skeleton" then return end
  local damage = fire.hero_damage or fire.damage or game:get_value("fire_damage") or 1
  damage = damage * 100 / (game:get_value("hero_defense_fire") or 100) --since savegame values must be ints
  --hero:start_hurt(fire, damage)
  --game:remove_life(damage)
  hero:process_hit{
    damage = damage,
    damage_type = "fire",
    non_staggering = true,
  }
  hero:build_up_status_effect("burn", 35)
  if game.start_status_effect and (math.random(1,100) <= 20) then
    game:start_status_effect("burn")
  end
end



--Ice
function hero_meta:react_to_ice(ice)
  if ice.harmless_to_hero then return end
  local hero = self
  local game = hero:get_game()

  if hero:is_blinking() then return end
  local damage = game:get_value("ice_damage") or 1
  damage = damage * 100 / (game:get_value("hero_defense_ice") or 100) --since savegame values must be ints
  hero:start_hurt(damage)
  if game.start_status_effect and (math.random(1,2) == 2) then
    game:start_status_effect("frozen")
  else
    hero:start_state(hero:get_ice_frozen_state())
    if hero:get_sprite():has_animation"frozen" then
      hero:set_animation"frozen"
    end
    sol.timer.start(hero, 2000, function() hero:set_animation"stopped" hero:unfreeze() end)
  end
end

function hero_meta:get_ice_frozen_state()
  local state = sol.state.create("ice_frozen") --note: "frozen" is a built in state
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_gravity_enabled(true)
  state:set_can_come_from_bad_ground(false)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(false)
  state:set_can_use_teletransporter(false)
  state:set_can_use_switch(true)
  state:set_can_use_stream(true)
  state:set_can_use_stairs(false)
  state:set_can_use_jumper(false)
  state:set_carried_object_action("throw")
  return state
end



--Lightning
function hero_meta:react_to_lightning(lightning)
  if lightning.harmless_to_hero then return end
  local hero = self
  local game = hero:get_game()

  if hero:is_blinking() then return end
  local damage = lightning.damage or game:get_value("lightning_damage") or 1
  damage = damage * 100 / (game:get_value("hero_defense_lightning") or 100) --since savegame values must be ints
  --hero:start_hurt(lightning, damage)
  hero:process_hit{
    damage = damage,
    damage_type = "lightning",
  }
end

function hero_meta:react_to_lightning_bolt(lightning)
  local hero = self
  local game = hero:get_game()

  if hero:is_blinking() then return end
  local damage = lightning.damage or game:get_value("lightning_damage") or 8
  damage = damage * 100 / (game:get_value("hero_defense_lightning") or 100) --since savegame values must be ints
  if hero.ragdoll then
    game:remove_life(damage)
    sol.audio.play_sound"hero_hurt"
    hero:stop_movement()
    hero:ragdoll(lightning:get_angle(hero), 100)
  else
    hero:start_hurt(lightning, damage)
  end
end
