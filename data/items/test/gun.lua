--[[
By Max Mraz. MIT License
A shield bash move to parry enemy attacks, designed to work with the Shadblow enemy system.
Basically just sets hero.parrying to true for a short window and plays an animation.
It's up to other code to determine what to do if hero.parrying is true.
Test version hardcodes the parry move to a key.
--]]

local item = ...
local game = item:get_game()

local shoot_command = "attack"
local item_range = 250

function item:on_started()
  local savegame_variable = "possession_gun"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
  item.range = item_range
end

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()
  local state = item:get_aim_state()
  local aim_key = "item_" .. (game:get_item_assigned(1) == item and 1 or 2)
  hero:start_state(state)
  hero:set_animation"bow_drawn"

  local enemies_in_range = {}
  local x,y,z = hero:get_position()
  for entity in map:get_entities_in_rectangle(x - item.range, y - item.range, item.range * 2, item.range * 2) do
    if entity:get_type() == "enemy" and entity:get_distance(hero) <= item.range then
      enemies_in_range[entity] = entity
    end
  end

  function state:on_command_released(command)
    if command == aim_key then
      hero:unfreeze()
      sol.timer.start(map,100, function() item:set_finished() end)
    end
  end

  function state:on_command_pressed(command)
    if command == shoot_command then
      item:fire()
      item:set_finished()
    elseif command == "right" then
      hero:set_direction(0)
    elseif command == "up" then
      hero:set_direction(1)
    elseif command == "left" then
      hero:set_direction(2)
    elseif command == "down" then
      hero:set_direction(3)
    end
  end
end


function item:stop_aiming()
  local hero = game:get_hero()
  hero:unfreeze()
  item:set_finished()
end


function item:fire()
  local hero = game:get_hero()
  local map = game:get_map()
  local direction = hero:get_direction()
  local x,y,z = hero:get_position()
  local step = 16
  local dx = {[0] = step, [1]=0, [2]= step * -1, [3]=0}
  local dy = {[0]=0, [1] = step * -1, [2]=0, [3]= step}
  local projectile = map:create_custom_entity{
    x = x + dx[direction], y = y + dy[direction], layer = z,
    width = 16, height = 16, direction = direction, 
    sprite = "entities/enemy_projectiles/generic_projectile", model = "hero_projectiles/ball",
  }
  projectile.damage = 2
  projectile.type = "magic"
  projectile:shoot(item:get_direction_held() * math.pi / 4)
end

function item:get_direction_held()
  local hero = game:get_hero()
  local up = game:is_command_pressed("up")
  local right = game:is_command_pressed("right")
  local left = game:is_command_pressed("left")
  local down = game:is_command_pressed("down")
  local direction = hero:get_direction() * 2
  if up and right then direction = 1
  elseif up and left then direction = 3
  elseif down and left then direction = 5
  elseif down and right then direction = 7
  elseif up then direction = 2
  elseif left then direction = 4
  elseif down then direction = 6
  elseif right then direction = 0
  end
  return direction
end


function item:get_aim_state()
  local hero = game:get_hero()
  local state = sol.state.create("aiming")
  state:set_can_control_direction(true)
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
