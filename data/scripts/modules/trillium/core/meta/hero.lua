-- Initialize hero behavior specific to this quest.

sol.modules.get_object("multi_events")

local hero_meta = sol.main.get_metatable("hero")



hero_meta:register_event("on_created", function(hero)
  hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED)
end)


--NOTE!!:
--Because this is a registered event, this can easily conflict with others if the damage amount is adjusted!
--Highly recommend not adjusting the damage amount anywhere unless you're sure what you're doing
hero_meta:register_event("on_taking_damage", function(hero, damage)
  local game = hero:get_game()
  --Trigger charm event:
  if game.event_manager then game.event_manager:trigger_event("on_hurt") end
  hero:start_iframes() --defined below
end)


function hero_meta:process_hit(props)
  local hero = self
  local game = hero:get_game()
  local damage = props.damage or 1
  local enemy = props.enemy
  local damage_type = props.damage_type or "physical"
  local non_staggering = props.non_staggering or false
  local state, state_ob = hero:get_state()

  if state_ob and not state_ob:get_can_be_hurt() then return end --don't hurt if you can't get hurt in current state
  if not hero:get_can_be_hurt() then return end --if you can't be hurt, then just don't
  if state == "jumping" then return end --if you got hurt while jumping down you'd get stuck in the wall

  if hero.calculate_input_damage then
    damage = hero:calculate_input_damage(damage, damage_type)
  end

  if hero.blood_splatter then hero:blood_splatter(enemy) end

  --Trigger charm event:
  if game.event_manager then game.event_manager:trigger_event("on_hit", enemy, damage) end

  --If hurt while swimming, immediately drown so you don't reset oxygen level:
  if state == "swimming" then
    hero:drown()
    hero.oxygen = 0
    return
  end

  if non_staggering then
    game:remove_life(damage)
    hero:start_iframes()
  else
    hero:start_hurt(damage)
  end
  --[[
  --Hitstop
  game:set_suspended(true)
  sol.timer.start(game, 20, function() game:set_suspended(false) end)
  --]]
  hero:get_map():get_camera():shake{shake_count = 12, amplitude = 3, zoom_scale = 1.02}
  game:rumble("hero_hurt")
end


--Note: this is kind of a messy function, just random shit that happens on state change is getting shoved in here:
hero_meta:register_event("on_state_changed", function(self, state)
  local hero = self
  local game = sol.main.get_game()

  if state == "back to solid ground" then
    hero:freeze()
    hero:set_visible(false)
    sol.timer.start(hero, 300, function()
      hero:set_visible(true)
      hero:unfreeze()
      hero:set_blinking(true, 1200)
      hero:set_invincible(true,1500)
    end)

  elseif state == "falling" then
    if hero.weapon_entity then hero.weapon_entity:remove() end

  end
end)


hero_meta:register_event("on_state_changing", function(hero, old_state, next_state)
  if old_state == "jumping" then
    sol.audio.play_sound("hero_lands")


  elseif next_state == "stairs" then
    hero:get_map().started_but_not_opening_transition_finished = true
    hero:set_animation"stopped"
    if hero.weapon_entity then hero.weapon_entity:remove() end

  end
end)


local MAX_BUFFER_SIZE = 48
hero_meta:register_event("on_position_changed", function(self, x, y, z)
  local hero = self
  if not hero.position_buffer then hero.position_buffer = {} end
  local hero = self
  local dir = hero:get_sprite():get_direction()
  table.insert(hero.position_buffer, 1, {x=x,y=y,layer=l,direction=dir})

  if #hero.position_buffer > MAX_BUFFER_SIZE then
    table.remove(hero.position_buffer)
  end
end)


function hero_meta:get_can_be_hurt()
  local hero = self
  local can_be_hurt = not hero:is_invincible()
  local state, state_ob = hero:get_state()
  if state == "custom" then state = state_ob:get_description() end
  if (state == "falling") or (state == "stairs") or (state == "treasure") or (state == "victory")
  or (state == "feather_jumping") then
    can_be_hurt = false
  end
  return can_be_hurt
end


function hero_meta:start_iframes(length)
  local hero = self
  local game = hero:get_game()
  local base_iframe_length = length or 200
  local iframe_length = base_iframe_length + (game:get_value("hurt_iframes_bonus") or 0)
  hero:set_invincible(true, iframe_length)
  hero:set_blinking(true, iframe_length)
end


function hero_meta:ragdoll(direction, distance, callback)
  local hero = self
  local state = sol.state.create("ragdolling")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
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
  hero:set_direction(sol.main.get_direction4(direction))
  hero:start_state(state)
  hero:set_animation"ragdolling"

  local function end_movement()
    hero:unfreeze()
    hero:freeze()
    hero:start_knock_down(700, callback)
  end

  local m = sol.movement.create"straight"
  m:set_speed(300)
  m:set_angle(direction)
  m:set_max_distance(distance)
  m:start(hero, function() end_movement() end)
  function m:on_obstacle_reached()
    m.on_obstacle_reached = nil
    end_movement()
  end

  sol.audio.play_sound("thump_01")
  sol.audio.play_sound("hero_hurt")
end


function hero_meta:start_knock_down(duration, callback)
  local hero = self
  local game = self:get_game()
  duration = duration or 700
  local state = sol.state.create("knocked_down")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_come_from_bad_ground(false)
  state:set_can_be_hurt(true)
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
  hero:start_state(state)
  hero:set_animation"knocked_down"
  sol.timer.start(hero, duration - 200, function()
    if not game.playing_knock_down_getup_sound then
      game.playing_knock_down_getup_sound = true
      sol.audio.play_sound"fabric_rustle"
      sol.timer.start(game, 100, function() game.playing_knock_down_getup_sound = false end)
    end
    hero:set_animation("getting_up", function()
      hero:set_direction(3)
      if callback then callback() else hero:unfreeze() end
    end)
  end)
end


function hero_meta:knock_up(stun_duration)
  local hero = self
  hero:freeze()
  --sol.timer.stop_all(hero)
  hero:set_animation("knocked_up", function()
    local dir = (hero:get_direction() + 2) % 4
    hero:set_direction(dir)
    hero:start_knock_down(stun_duration)
  end)
end


function hero_meta:step_forward(distance, speed)
  local hero = self
  local map = self:get_map()
  distance = distance or 8
  speed = speed or 90
  local speed_mod = (distance - 24) * 4
  if distance > 24 then speed = speed + speed_mod end
  local angle = hero:get_direction() * math.pi / 2

  local m = sol.movement.create("straight")
  m:set_angle(angle)
  m:set_speed(speed)
  m:set_max_distance(distance)
  m:start(hero)
end


function hero_meta:has_los(entity) 
  local los = true
  local map = self:get_map()
  local x, y, z = self:get_position()
  local dx, dy = 0, 0
  local distance = self:get_distance(entity)
  local angle = self:get_angle(entity)
  for i=0, distance do
    dx, dy = math.floor(math.cos(angle)*i), -math.floor(math.sin(angle)*i)
    if self:test_obstacles(dx, dy) then
        local ground = map:get_ground(x + dx, y + dy, z)
        if ground ~= "deep_water" and ground ~= "shallow_water" and ground ~= "hole" and ground ~= "lava" then
          los = false
          break
        end
    end
  end

  return los
end


function hero_meta:start_spellcasting(duration,callback)
  local casting_state = sol.state.create("casting")
  local hero = self
  casting_state:set_can_control_direction(false)
  casting_state:set_can_control_movement(false)
  casting_state:set_can_use_item(false)
  hero:start_state(casting_state)
  sol.timer.start(casting_state, duration, function()
    callback()
  end)
  return casting_state
end


function hero_meta:stun(duration)
  local hero = self
  duration = duration or 2000 --default duration: 2000ms
  local state = sol.state.create("stunned")
  state:set_can_control_direction(false)
  state:set_can_control_movement(false)
  state:set_can_come_from_bad_ground(false)
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
  hero:start_state(state)
  hero:set_animation("stunned")
  sol.timer.start(hero, duration, function()
    hero:set_animation"stopped"
    hero:unfreeze()
  end)
end


return true