--[[
By Max Mraz. MIT License
A shield bash move to parry enemy attacks, designed to work with the Shadblow enemy system.
Basically just sets hero.parrying to true for a short window and plays an animation.
It's up to other code to determine what to do if hero.parrying is true.
Test version hardcodes the parry move to a key.
--]]

local item = ...
local game = item:get_game()

local parry_key = "a"
local parry_window = 150
local parry_cooldown = false

function item:on_started()
  local savegame_variable = "possession_shield_bash"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
end

function item:on_using()
  local hero = game:get_hero()
  hero:freeze()
  --hero:start_state(item:get_bashing_state())
  hero.parrying = true
  sol.timer.start(hero, parry_window, function() hero.parrying = false end)
  local shield_sprite = hero:get_sprite"shield"
  if not shield_sprite then shield_sprite = hero:create_sprite("hero/shield", "shield") end
  local direction = hero:get_direction()
  if direction == 1 then hero:bring_sprite_to_back(shield_sprite) end
  shield_sprite:set_direction(direction)
  shield_sprite:set_animation("parry", function()
    if hero:get_sprite"shield" then hero:remove_sprite(shield_sprite) end
  end)
  hero:set_animation("parry", function()
    hero:unfreeze()
    item:set_finished()
  end)
end


function item:get_bashing_state()
  local hero = game:get_hero()
  local state = sol.state.create("shield_bashing")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_gravity_enabled(true)
  state:set_can_come_from_bad_ground(true)
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


--Add parrying to hero metatable

local hero_meta = sol.main.get_metatable("hero")

function hero_meta:parry(enemy)
  local hero = self
  sol.audio.play_sound("shield")
  sol.audio.play_sound("door_open")
  enemy:stun(1400)
end
