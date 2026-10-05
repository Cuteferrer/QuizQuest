--[[
By Max Mraz, licensed MIT

Necessary resources:
sprites/status_effects/status_effect
- sprite, if you want a sprite to play on the hero when they're affected by a status effect, it must have an animation here

game:get_status_effects() returns a table of all status effects that have been activated (ones that are not currently active will be nil)
That table would look something like this:
game:get_status_effects() ->
{
  poison = {
    timer = [a timer object],
    type = "poison",
  },
  swim_speed_boost = {
    timer = [a timer object],
    type = "swim_speed_boost",
  },
}

Note: status_effects timers do NOT show total remaining time, they loop for a duration

You can also "build up" a status effect rather than starting it outright. For example, a poison swamp builds up toward a poison effect, so if you spend too long in it you'll be poisoned
Call hero:build_up_status_effect(effect, amount) to add an amount of "points" toward the effect
Reaching 100 or more points will trigger the effect (and reset the amount of points to 0 for that effect)
Status points are removed at a constant rate (decrement_rate, see below)
someone should make a HUD so this is visible to the player lol
--]]

local manager = {}
local game_meta = sol.main.get_metatable"game"
local hero_meta = sol.main.get_metatable"hero"
local status_effects = {}
local building_status_effects = {}
local status_immunities = {}
local status_effect_reference_sprite = sol.sprite.create"status_effects/status_effect"

local decrement_rate = 850 --every x ms, status buildup is decremented
local default_decrement_amount = 6 --amount by which status buildup is decremented
local decrement_amounts = {
  poison = 4,
}


function hero_meta:get_status_effects()
  return status_effects
end


function hero_meta:get_status_immunities()
  return status_immunities
end


--All effects must be processed here. Duration can be:
--a number (milliseconds), "map" (effect lasts while on map), or "infinite" (effect lasts until game:stop_status_effect() is called)
function hero_meta:start_status_effect(effect, duration)
  local hero = self
  local game = hero:get_game()
  if status_immunities[effect] then
    return
  elseif hero:is_status_effect_active(effect) then
    return
  end
  status_effects[effect] = {}
  status_effects[effect].type = effect
  if effect == "poison" then
    manager:start_dps(effect, 5, 2000, duration or 16000)

  elseif effect == "acid" then
    manager:start_dps(effect, 7, 500, duration or 5000)

  elseif effect == "burn" then
    manager:start_dps(effect, 10, 1000, duration or 5000)

  elseif effect == "cold" then
    manager:start_dps(effect, 2, 2000, duration or 15000)
    status_effects[effect].map_id = game:get_map():get_id()

  elseif effect == "sunstroke" then
    manager:start_dps(effect, 5, 3000, "map")
    status_effects[effect].map_id = game:get_map():get_id()

  elseif effect == "hex" then
    game:set_magic(0)
    game:set_magic_regen_multiplier(nil, 0)
    status_effects[effect].timer = sol.timer.start(game, duration or 60000, function()
      game:set_magic_regen_multiplier(nil, 1)
      hero:stop_status_effect(effect)
    end)

  elseif effect == "frozen" then
    hero:start_state(manager:get_frozen_state())
    if hero:get_sprite():has_animation("frozen") then
      hero:set_animation("frozen")
    end
    status_effects[effect].timer = sol.timer.start(game, duration or 3000, function()
      hero:set_animation"stopped"
      hero:unfreeze()
      hero:stop_status_effect(effect)
    end)

  elseif effect == "webbed" then
    hero:freeze()
    hero:start_state(manager:get_frozen_state())
    if hero:get_sprite():has_animation("webbed") then
      hero:set_animation("webbed")
    end
    status_effects[effect].timer = sol.timer.start(game, duration or 2000, function()
      hero:set_animation"stopped"
      hero:unfreeze()
      hero:stop_status_effect(effect)
    end)

  elseif effect == "immobilized" then
    hero:freeze()
    hero:start_state(manager:get_frozen_state())
    status_effects[effect].timer = sol.timer.start(game, duration or 2500, function()
      hero:set_animation"stopped"
      hero:unfreeze()
      hero:stop_status_effect(effect)
    end)

  elseif effect == "bleed" then
    hero:process_hit({
      damage = game:get_max_life() * .15 + 50,
      non_staggering = true,
    })
    status_effects[effect].timer = sol.timer.start(game, duration or 15000, function()
      hero:stop_status_effect(effect)
    end)

  else
    error("nonexistant status effect called with game:start_status_effect()")
  end
  if status_effect_reference_sprite:has_animation(effect) then
    hero:start_status_sprite(effect)
  end

  --Show HUD Message:
  game:show_hud_message(sol.language.get_string("game.status_effect." .. effect))
end



function hero_meta:stop_status_effect(effect)
  local hero = self
  local game = hero:get_game()
  if status_effects[effect] then
    status_effects[effect].timer:stop()
    status_effects[effect] = nil
  end
  local effect_sprite = hero:get_sprite("status_effect_" .. effect)
  if effect_sprite then hero:remove_sprite(effect_sprite) end
  hero:clear_status_effect_buildup(effect) --Also removes buildup toward this effect.
  --Note: this means items that do hero:stop_status_effect() will also cure buildup if the effect isn't active. This is intentional, but you may not want it.
end


function hero_meta:is_status_effect_active(effect)
  local hero = self
  local is_active = false
  for _, v in pairs(status_effects) do
    if v.type == effect then is_active = true end
  end
  return is_active
end


function hero_meta:start_status_sprite(effect)
  local hero = self
  local game = hero:get_game()
  local sprite = hero:create_sprite("status_effects/status_effect", "status_effect_" .. effect)
  sprite:set_animation(effect)
end


function hero_meta:cure_all_status_effects()
  local hero = self
  for _, effect in pairs(status_effects) do
    hero:stop_status_effect(effect.type)
  end
end


function hero_meta:start_status_immunity(effect, duration)
  local hero = self
  local game = hero:get_game()
  if status_immunities[effect] then status_immunities[effect].timer:stop() end
  status_immunities[effect] = {}
  status_immunities[effect].type = effect
  if duration ~= "infinite" then
    status_immunities[effect].timer = sol.timer.start(game, duration, function()
      status_immunities[effect] = nil
    end)
  end
  hero:stop_status_effect(effect)
end


function hero_meta:stop_status_immunity(effect)
  local hero = self
  if status_immunities[effect] and status_immunities[effect].timer then status_immunities[effect].timer:stop() end
  status_immunities[effect] = nil
end



function manager:start_dps(effect, amount, rate, duration)
  local game = sol.main.get_game()
  local hero = game:get_hero()
  local elapsed_time = 0
  --if duration is "map", set a timer to check that we're still on the same map
  if duration == "map" then
    sol.timer.start(game, 500, function()
      if status_effects[effect] and status_effects[effect].map_id == game:get_map():get_id() then
        return true
      else
        hero:stop_status_effect(effect)
      end
    end)
  end
  --Start a timer to do damage
  status_effects[effect].timer = sol.timer.start(game, rate, function()
    elapsed_time = elapsed_time + rate
    game:remove_life(amount)
    sol.audio.play_sound"hero_hurt_small"
    if (duration == "infinite") or (duration == "map") then
      return true
    elseif (elapsed_time < duration) then
      return true
    else
      hero:stop_status_effect(effect)
    end
  end)
  status_effects[effect].timer:set_suspended_with_map(true)
end


function manager:get_frozen_state()
  local state = sol.state.create()
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_use_sword(false)
  state:set_can_use_item(false)
  state:set_can_interact(false)
  state:set_can_grab(false)
  state:set_can_push(false)
  state:set_can_pick_treasure(false)
  return state
end


function hero_meta:build_up_status_effect(effect, amount)
  local hero = self
  local game = hero:get_game()

  local state, state_ob = hero:get_state(), hero:get_state_object()
  if state_ob and (state_ob:get_can_be_hurt() == false) then return end --don't build up status while you're dashing
  if hero:is_status_effect_active(effect) then return end --Don't build up points towards an effect that is already active
  --Increment amount:
  if not building_status_effects[effect] then building_status_effects[effect] = 0 end
  building_status_effects[effect] = building_status_effects[effect] + amount

  --Start effect if we breach threshold
  local breach_threshold = game:get_value("status_resistance_" .. effect) or 100
  if building_status_effects[effect] >= breach_threshold then
    local breached_amount = building_status_effects[effect] - breach_threshold --calculate how much we went over the threshold by
    --Wait a sec before lowering status so bars can show 100% and stuff
    sol.timer.start(game,100, function()
      building_status_effects[effect] = 0
    end)
  end

  --Hook for events
  if hero.on_status_build_up then
    hero:on_status_build_up(effect)
  end

  --Timer to gradually bring amounts back down
  if not hero.status_buildup_timer then
    hero.status_buildup_timer = sol.timer.start(game, decrement_rate, function()
      local is_buildup = false
      for status, current_amount in pairs(building_status_effects) do
        local decrement_amount = decrement_amounts[status] or default_decrement_amount
        building_status_effects[status] = math.max(building_status_effects[status] - decrement_amount, 0)
        if not is_buildup then
          is_buildup = building_status_effects[status] > 0
        end
      end
      --Re-run if there's still any buildup, otherwise we can stop the timer
      if is_buildup then
        return true
      else
        hero.status_buildup_timer = nil
      end
    end)
    hero.status_buildup_timer:set_suspended_with_map(true)
  end
end


function hero_meta:reduce_status_effect_buildup(effect, amount)
  local current_amount = building_status_effects[effect] or 0
  building_status_effects[effect] = math.max(current_amount - amount, 0)
end


function hero_meta:get_status_effect_buildup(effect)
  local hero = self
  local amount = building_status_effects[effect] or 0
  return amount
end


function game_meta:get_status_effect_resistance(effect)
  return self:get_value("status_resistance_" .. effect) or 100
end


function game_meta:set_status_effect_resistance(effect, amount)
  self:set_value("status_resistance_" .. effect, amount)
end


function hero_meta:clear_status_effect_buildup(effect)
  building_status_effects[effect] = nil
end


function hero_meta:clear_all_status_buildup()
  building_status_effects = {}
end


game_meta:register_event("on_game_over_started", function(self)
  local hero = self:get_hero()
  hero:cure_all_status_effects()
  hero:clear_all_status_buildup()
end)


function hero_meta:get_status_buildup_decrement_amount(effect)
  return decrement_amounts[effect]
end


function hero_meta:set_status_buildup_decrement_amount(effect, new_amount)
  decrement_amounts[effect] = new_amount
end



return manager