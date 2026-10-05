--[[
Created by Max Mraz, licensed MIT
Fast travel points

Entity properties:
id: required. Corresponds with travel point IDs in scripts/modules/trillium/fast_travel/travel_points
locked: optional - will be locked until you pay a toll
toll_amount: required if locked - how much is price of toll to unlock travel point
--]]

local map_meta = sol.main.get_metatable"map"
local fast_travel_menu = sol.modules.get_object("fast_travel_menu")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  entity.travel_point_id = entity:get_property("id")

  entity:init_locked()
end


function entity:show_interact_icon(hero)
  return hero:get_direction() == 1
end


function entity:on_interaction(hero)
  if hero:get_direction() ~= 1 then
    --Only can pull bell from south side
    return
  elseif entity:get_locked() then
    if entity:get_property("toll_amount") then
      entity:toll_question()
    else
      entity:unlock()
    end
  else
    entity:ring_bell()
  end
end



function entity:ring_bell()
  --Unlock this fast travel point
  game:unlock_fast_travel_point(entity.travel_point_id)
  local has_coin = game:has_item("gear/charon_coin")
  local sprite = entity:get_sprite()
  sprite:set_ignore_suspend(true)
  sprite:set_animation("ringing")
  local rings = 1
  sol.timer.start(entity, 270, function()
    rings = rings + 1
    sol.audio.play_sound("bell")
    if rings < 5 then
      return 720
    else
      sol.timer.start(entity, 360, function()
        sprite:set_animation("stopped")
      end):set_suspended_with_map(false)
      if has_coin then entity:summon_charon() end
    end
  end):set_suspended_with_map(false)
  if has_coin then
    --Freeze game so you can't get attacked during this:
    map:start_cutscene()
    game:set_suspended(true)
    hero:freeze()
    hero:set_animation"walking"
    hero:get_sprite():set_ignore_suspend(true)
    local function stop_walkin_here()
      hero:set_animation"stopped"
      hero:get_sprite():set_ignore_suspend(false)
    end
    local m = sol.movement.create"straight"
    m:set_ignore_suspend(true)
    m:set_angle(3 * math.pi / 2)
    m:set_max_distance(32)
    m:start(hero, stop_walkin_here)
    m.on_obstacle_reached = stop_walkin_here
  end
end


function entity:summon_charon()
  local x, y, z = entity:get_position()
  local starting_offset = -256

  local charon = map:create_charon(x + starting_offset, y + 24, z)
  entity.charon = charon --to access him from other functions
  charon:fade_in()
  sol.audio.play_sound("scenes/ghost_wind")
  local m = sol.movement.create"straight"
  m:set_ignore_suspend(true)
  m:set_angle(0)
  m:set_speed(200)
  m:set_acceleration(charon, -15)
  m:set_ignore_obstacles(true)
  m:set_max_distance(math.abs(starting_offset) + 8)
  m:start(charon, function()
    charon:set_animation"stopped"
    sol.timer.start(map, 1000, function()
      game:start_dialog("menus.fast_travel.charon_greeting", function()
        fast_travel_menu.travel_callback = entity.travel_callback
        sol.menu.start(game, fast_travel_menu)
      end)
    end):set_suspended_with_map(false)
  end)
end


function entity.travel_callback(selected_location)
  local charon = entity.charon

  local function unfreeze_game()
    hero:unfreeze()
    map:stop_cutscene()
    game:set_suspended(false)
  end

  local function get_in(callback)
    charon:open_door()
    sol.timer.start(map, 1000, function()
      hero:set_animation"walking"
      local m = sol.movement.create"straight"
      m:set_angle(math.pi / 2)
      m:set_max_distance(28)
      m:set_ignore_obstacles(true)
      m:set_ignore_suspend(true)
      m:start(hero, function()
        hero:set_animation"stopped"
        callback()
      end)
    end):set_suspended_with_map(false)
  end

  local function drive_off(callback)
    sol.audio.play_sound("scenes/ghost_wind_short")
    local m = sol.movement.create"straight"
    m:set_speed(100)
    m:set_acceleration(charon, 25)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    m:start(charon)
    charon:fade_out()
    sol.timer.start(map, 2000, function()
      callback()
    end):set_suspended_with_map(false)
  end

  --Cancel ride
  if selected_location == "cancel" then
    sol.timer.start(map, 300, function()
      game:start_dialog("menus.fast_travel.cancel", function()
        charon:set_animation("walking_angry")
        drive_off(function()
          unfreeze_game()
        end)
      end)
    end):set_suspended_with_map(false)

  --Already there:
  elseif selected_location == entity.travel_point_id then
    game:start_dialog("menus.fast_travel.already_here", function()
      get_in(function()
        charon:set_animation("walking")
        drive_off(function()
          hero:set_direction(0)
          unfreeze_game()
        end)
      end)
    end)

  --Actual Trip
  else
    get_in(function()
      hero:set_visible(false)
      sol.timer.start(map, 500, function()
        charon:set_animation("walking")
        drive_off(function()
          game:set_suspended(false) --don't unfreeze_game() because we still want cutscene active and hero frozen
          game:fast_travel(selected_location)
        end)
      end):set_suspended_with_map(false)
    end)
  end
end






--Locked:
function entity:init_locked()
  local sprite = entity:get_sprite()
  if not game:get_fast_travel_point_unlocked(entity.travel_point_id) then
    entity.locked = true
    sprite:set_animation("locked")
  end
end


function entity:get_locked()
  return entity.locked or false
end


function entity:unlock()
  local sprite = entity:get_sprite()
  --Unlock this fast travel point
  hero:freeze()
  game:unlock_fast_travel_point(entity.travel_point_id)
  entity.locked = false
  --Animation / Sound:
  sprite:set_animation("unlock", function()
    sprite:set_animation("stopped")
  end)
  sol.audio.play_sound("device_set")
  sol.audio.play_sound("mechanical_track_very_short")
  sol.timer.start(map, 100, function()
    sol.audio.play_sound("impact_metal_2")
  end)
  sol.timer.start(map, 400, function()
    sol.audio.play_sound("door_unlocked")
    sol.sound.create("bell_low_long"):play()
  end)
  if not game:has_item("gear/charon_coin") then
    sol.timer.start(map, 1100, function()
      game:start_dialog("world_objects.fast_travel.bellpost_activated", function()
        hero:unfreeze()
      end)
    end)
  else
    sol.timer.start(map, 800, function()
      game:show_hud_message(sol.language.get_string"game.hud_messages.bellpost_unlocked")
    end)
    hero:unfreeze()
  end
end


function entity:toll_question()
  local toll_amount = tonumber(entity:get_property("toll_amount"))
  assert(toll_amount, "Cannot have a locked fast travel point without a 'toll_amount' property")
  game:start_dialog(
    "world_objects.fast_travel.toll_question",
    { v1 = toll_amount },
    function(answer)
      if answer == 1 then
        if game:get_money() >= toll_amount then
          game:remove_money(toll_amount)
          entity:unlock()
        else
          game:start_dialog("game.insufficient_funds")
        end
      end
    end
  )
end


