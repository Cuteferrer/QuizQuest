--[[
By Max Mraz. MIT License
A shield bash move to parry enemy attacks, designed to work with the Shadblow enemy system.
Basically just sets hero.shielding to true while the shield is held up. Other code must determine what to do with that.
Test version hardcodes the shield to a key.
--]]


local item = ...
local game = item:get_game()

function item:on_started()
  local savegame_variable = "possession_parrying_test_item"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
end

function item:on_using()
  item:raise_shield()
end


function item:raise_shield()
  local hero = game:get_hero()
  local shield_sprite = hero:get_sprite"shield"
  if not shield_sprite then shield_sprite = hero:create_sprite("hero/shield", "shield") end
  local direction = hero:get_direction()
  shield_sprite:set_direction(direction)
  if direction == 1 then hero:bring_sprite_to_back(shield_sprite) end
  shield_sprite:set_animation("raise", function()
    shield_sprite:set_animation("stopped")
    hero.shielding = true
  end)
  hero:start_state(item:get_shield_state())
end


function item:lower_shield()
  local hero = game:get_hero()
  local shield_sprite = hero:get_sprite"shield"
  if not shield_sprite then shield_sprite = hero:create_sprite("hero/shield", "shield") end
  hero:unfreeze()
  if hero:get_sprite("shield") then hero:remove_sprite(shield_sprite) end
  hero.shielding = false
  parry_cooldown = true
  sol.timer.start(hero, 300, function() parry_cooldown = false end)
  item:set_finished()
end


function item:get_shield_state()
  local state = sol.state.create("shielding")
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
  state:set_can_be_hurt(true)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(true)
  state:set_can_use_teletransporter(true)
  state:set_can_use_switch(true)
  state:set_can_use_stream(true)
  state:set_can_use_stairs(true)
  state:set_can_use_jumper(true)
  state:set_carried_object_action("throw")

  return state
end
