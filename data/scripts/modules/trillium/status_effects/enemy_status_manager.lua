--[[
By Max Mraz, licensed MIT
Provides functions to impart status effects to enemies

--]]

local mager = {}

local enemy_meta = sol.main.get_metatable"enemy"

local decrement_rate = 500 --every x ms, status buildup is decremented
local default_decrement_amount = 1 --amount by which status buildup is decremented
local decrement_amounts = { --overrides for default decrement amounts
  poison = 2,
  shock = 3,
}

--Configure how damage is dealt with each status effect here. It's defined as a method of the enemy, so you can run a function that takes the enemy into account to return different amounts of damage or duration of effect in different cases
function enemy_meta:get_status_effect_config(effect)
  local enemy = self
  local amount, rate, duration, sound
  rate = 1000 --damage is per second, unless overridden
  if effect == "burn" then
    amount = 20
    duration = 5000
    sound = "fireball"

  elseif effect == "cold" then
    amount = 5
    duration = 10000
    sound = "frost2"

  elseif effect == "shock" then
    amount = 0
    duration = 2000
    sound = "electric_zap_big"

  elseif effect == "poison" then
    amount = 10
    duration = 20000
    sound = "bush"

  elseif effect == "bleed" then
    amount = nil
    duration = 15000
    sound = "bush"

  end
  return {
    amount = amount,
    rate = rate,
    duration = duration,
    start_sound = sound,
  }
end


--Configure effects of status here. Most provided effects start DPS on the enemy, but this can be configured to do anything when the status starts. Remember to somehow stop the status eventually
function enemy_meta:start_status_effect(effect, duration)
  assert(effect, "You cannot call start_status_effect without specifying an effect")
  local enemy = self
  local map = enemy:get_map()
  if not enemy.status_effects then enemy.status_effects = {} end
  --restart the effect if it's already active
  if enemy:is_status_effect_active(effect) then
    enemy:stop_status_effect(effect)
  end

  local config = enemy:get_status_effect_config(effect)
  local amount, rate = config.amount, config.rate
  duration = duration or config.duration --this allows overriding the duration
  enemy.status_effects[effect] = {}
  enemy.status_effects[effect].type = effect

  if config.start_sound then sol.audio.play_sound(config.start_sound) end

  --note: dps takes arguments: effect, amount, rate, duration
  if effect == "burn" then
    enemy:start_status_effect_dps(effect, amount, rate, duration)
    enemy:start_status_effect_particles(effect, 150)

  elseif effect == "cold" then
    enemy:start_status_effect_dps(effect, amount, rate, duration)
    enemy:start_status_effect_particles(effect, 100)

  elseif effect == "shock" then
    enemy:start_status_effect_particles(effect, 100)
    --enemy:hurt(amount)
    --[[
    enemy:immobilize(duration)
    sol.timer.start(map, duration, function()
      enemy:stop_status_effect(effect)
    end)
    --]]

  elseif effect == "poison" then
    enemy:start_status_effect_dps(effect, amount, rate, duration)
    enemy:start_status_effect_particles(effect, 300)

  elseif effect == "bleed" then
    enemy:process_hit({damage = (enemy.max_life or 200) * .15 + 50, damage_type = "physical", stagger_value = 0})
    enemy:start_status_effect_particles(effect, 300)
    sol.audio.play_sound"enemy_hurt"
    sol.timer.start(map, duration, function()
      enemy:stop_status_effect(effect)
    end)

  elseif effect == "blood_offering_buff" then --this one only exists to add the particle effects
    enemy:start_status_effect_particles(effect, 300)
    enemy.blood_buffed = true

  else
    error("Nonexistant enemy status started with enemy:start_status_effect: " .. effect)

  end
end



function enemy_meta:stop_status_effect(effect)
  local enemy = self
  if not enemy.status_effect_particle_timers then enemy.status_effect_particle_timers = {} end
  if not enemy.status_effects[effect] then enemy.status_effects[effect] = {} end
  if enemy.status_effects[effect] then
    --stop internal status timer
    if enemy.status_effects[effect].timer then
      enemy.status_effects[effect].timer:stop()
    end
    --end status effect
    enemy.status_effects[effect] = nil
    --remove sprites
    if enemy.status_effect_particle_timers[effect] then
      enemy.status_effect_particle_timers[effect]:set_remaining_time(0)
    end
  end
end



--Returns whether a given status effect is active if specified. If none is specified, returns whether or not ANY status is active
function enemy_meta:is_status_effect_active(effect)
  local enemy = self
  local is_active = false
  if effect == nil then --check if any effect is active
    for _, v in pairs(enemy.status_effects or {}) do
      if v.type then is_active = true end
    end
  else --check if specified effect is active
    for _, v in pairs(enemy.status_effects or {}) do
      if v.type == effect then is_active = true end
    end
  end
  return is_active
end



function enemy_meta:build_up_status_effect(effect, amount)
  local enemy = self
  local game = enemy:get_game()
  amount = amount or 20
  local activate_threshold = enemy.status_resistances and enemy.status_resistances[effect] or 100

  if not enemy.building_status_effects then enemy.building_status_effects = {} end
  if enemy:is_status_effect_active(effect) then return end --Don't build up points towards an effect that is already active

  --Increment amount:
  if not enemy.building_status_effects[effect] then enemy.building_status_effects[effect] = 0 end
  enemy.building_status_effects[effect] = enemy.building_status_effects[effect] + amount

  --Start effect if we breach threshold
  if enemy.building_status_effects[effect] >= activate_threshold then
    enemy:start_status_effect(effect) --calling without duration means default duration
    enemy.building_status_effects[effect] = 0
  end

  --Timer to gradually bring amounts back down
  if not enemy.status_buildup_timer then
    enemy.status_buildup_timer = sol.timer.start(game, decrement_rate, function()
      local is_buildup = false
      for status, current_amount in pairs(enemy.building_status_effects) do
        local decrement_amount = decrement_amounts[status] or default_decrement_amount
        enemy.building_status_effects[status] = math.max(enemy.building_status_effects[status] - decrement_amount, 0)
        if not is_buildup then
          is_buildup = enemy.building_status_effects[status] > 0
        end
      end
      --Re-run if there's still any buildup, otherwise we can stop the timer
      if is_buildup then
        return true
      else
        enemy.status_buildup_timer = nil
      end
    end)
  end
end


function enemy_meta:start_status_effect_dps(effect, amount, rate, duration)
  local enemy = self
  local game = sol.main.get_game()
  local map = self:get_map()
  local elapsed_time = 0
  local damage_type = "physical"
  if effect == "burn" then damage_type = "fire"
  elseif effect == "cold" then damage_type = "ice" end
  --Start a timer to do damage
  enemy.status_effects[effect].timer = sol.timer.start(map, 0, function()
    if not enemy:exists() then return false end
    if enemy:get_life() <= 0 then return false end
    elapsed_time = elapsed_time + rate
    --enemy:remove_life(amount)
    enemy:process_hit({damage = amount, damage_type = damage_type, stagger_value = 0, sound_override = "enemy_hurt_small"})
    if (duration == "infinite") then
      return rate
    elseif (elapsed_time < duration) then
      return rate
    else
      enemy:stop_status_effect(effect)
    end
  end)
  enemy.status_effects[effect].timer:set_suspended_with_map(true)
end


function enemy_meta:start_status_effect_particles(effect, frequency, num_particles)
  local enemy = self
  local map = enemy:get_map()
  local sprite = enemy:get_sprite()
  local width, height = sprite:get_size()
  --local width, height = enemy:get_size()
  frequency = frequency or 200
  num_particles = num_particles or (width * height / 64)

  if not enemy.status_effect_particle_timers then enemy.status_effect_particle_timers = {} end

  local particle_sprites = {}
  for i = 1, num_particles do
    local sprite = enemy:create_sprite("status_effects/enemy_status_particle")
    enemy:set_attack_consequence_sprite(sprite, "sword", "ignored")
    enemy:set_attack_consequence_sprite(sprite, "explosion", "ignored")
    particle_sprites[i] = sprite
  end

  local i = 1
  enemy.status_effect_particle_timers[effect] = sol.timer.start(map, frequency, function()
    if enemy:get_life() <= 0 then return false end
    local sprite = particle_sprites[i]
    sprite:set_xy(math.random(width/2 * -1, width/2), math.random(height * -1 + 16, -4))
    sprite:set_animation(effect, function()
      sprite:set_animation("invisible")
    end)
    i = i + 1
    if i > num_particles then i = 1 end
    if enemy:is_status_effect_active(effect) then
      return true
    else
      for i = 1, num_particles do
        enemy:remove_sprite(particle_sprites[i])
      end
    end
  end)
end


return manager
