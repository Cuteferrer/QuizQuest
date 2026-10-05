--[[
Created by Max Mraz, licensed MIT
An entity to place under platforms, so that when the hero falls to the layer below they also are moved a set amount "south" to give the illusion of falling

Config:
- entity property:
    "fall_height" (default 32)
    set a "fall_height" property to set how far the player will "fall" to the south after stepping off a platform

- map setup:
    You will need to set this entity on a buffer layer of the map between the "ground" the player will land on and the "platforms" the player will fall from.
    Touching this entity will make the player fall, so it cannot be on the layer with the platforms, or on the ground below. Hence, the buffer layer.

--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local min_fall = 32


local landable_grounds = {
  ["empty"] = true,
  ["traversable"] = true,
  ["shallow_water"] = true,
  ["deep_water"] = true,
  ["grass"] = true,
  ["hole"] = true,
  ["ice"] = true,
  ["ladder"] = true,
  ["prickles"] = true,
  ["lava"] = true,
}

local bad_grounds = {
  ["wall"] = true,
  ["low_wall"] = true,
  ["wall_top_right"] = true,
  ["wall_top_left"] = true,
  ["wall_bottom_right"] = true,
  ["wall_bottom_left"] = true,
  ["wall_top_right_water"] = true,
  ["wall_top_left_water"] = true,
  ["wall_bottom_right_water"] = true,
  ["wall_bottom_left_water"] = true,
}


function entity:on_created()
  entity:set_visible(false)
  min_fall = entity:get_property("fall_height") or 32

  entity:add_collision_test("origin", function(entity, other)
    if other:get_type() == "hero" and not entity.moving_hero then
      local hero = other
      if hero:get_ground_below() ~= "empty" then return end --don't move the player down unless they're 
      local hero = other
      local state = hero:get_state()
      if (state == "free") or (state == "falling") or (state == "walking") then --cause the player to fall
        entity:fall_hero(hero)
      end
    end
  end)
end


local function can_land(hero)
  local init_ground = hero:get_ground_below()
  if bad_grounds[init_ground] then return false end --can't land if hero is on a wall
  --if the hero is on a passable ground, we still must check they don't overlap a wall:
  --Check if stuck in a wall:
  local stuck = false
  local layer = hero:get_layer()
  local ox, oy, width, height = hero:get_bounding_box()
  for dy = 0, height - 1 do
    for dx = 0, width - 1 do
      local ground = map:get_ground(ox + dx, oy + dy, layer)
      if bad_grounds[ground] then
        stuck = true
        break
      end
    end
  end
  return not stuck
end


function entity:fall_hero(hero)
  entity.moving_hero = true
  sol.audio.play_sound"fabric_rustle"
  local fall_state = entity:get_state()
  hero:snap_to_grid()
  hero:start_state(fall_state)
  hero:set_direction(3)
  hero:set_animation"jumping_down"
  --Move player down:
  local m = sol.movement.create"straight"
  m:set_angle(3 * math.pi / 2)
  m:set_speed(300)
  m:set_max_distance(min_fall - 8)
  m:set_ignore_obstacles(true)
  m:start(hero, function()

    local function move_further()
      local m = sol.movement.create"straight"
      m:set_angle(3 * math.pi / 2)
      m:set_speed(300)
      m:set_ignore_obstacles(true)
      m:set_max_distance(2)
      m:start(hero, function()
        if can_land(hero) then
          sol.audio.play_sound"hero_lands"
          hero:set_animation("landing", function()
            hero:unfreeze()
          end)
        else
          move_further()
        end
      end)
    end

    move_further()
  end)
end


--Falling state:
function entity:get_state()
  local hero = game:get_hero()
  local state = sol.state.create("z_adjust_falling")
  state:set_can_control_direction(true)
  state:set_can_control_movement(false)
  state:set_can_traverse_ground("hole", true)
  state:set_can_traverse_ground("deep_water", true)
  state:set_can_traverse_ground("lava", true)
  state:set_affected_by_ground("hole", false)
  state:set_affected_by_ground("deep_water", false)
  state:set_affected_by_ground("lava", false)
  state:set_gravity_enabled(true)
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

  function state:on_started()
  end

  function state:on_finished()
    entity.moving_hero = false
  end

  return state
end


