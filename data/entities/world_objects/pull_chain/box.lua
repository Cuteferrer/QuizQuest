--[[
Created by Max Mraz, licensed MIT
A long chain that the hero can pull to cause effects on the map.
This entity has 3 events:

entity:on_links_changed(num_links, direction)
      --a less granular event, called whenever a link in the chain goes in/out of the source box. "num_links" is how many links of chain are visible. Direction is "1" (chain is being pulled) or "-1" (chain is retracting).
entity:on_length_changed(length, direction)
    --called whenever the length of the chain changes. "length" is the length of the chain in pixels. Direction is "1" (chain is being pulled) or "-1" (chain is retracting).
    --on_length_changed is fairly noisy, especially near the end of the chain's full length
entity:on_full_pull()
    --called when the chain is pulled to its full extent

Entity properties:
max_length: the max length the chain can be pulled. Also triggers entity:on_full_pull() event
retract_speed: how fast the chain retracts when dropped and it reels itself in

--]]

local SLOW_AMOUNT = 60 --edit this to change by how much the player slows down while they're pulling the chain
local LINK_SIZE = 8 --how close the links are to each other

local entity = ...
local game = entity:get_game()
local map = entity:get_map()


--Pulling state:
function entity:get_pulling_state()

  local state = sol.state.create("chain_pulling")
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
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

  function state:on_started()
    local hero = state:get_entity()
    assert(state.handle, "Cannot start the 'chain_pulling' state without assigning a handle entity to state.handle")
    hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED - SLOW_AMOUNT)
    hero:set_animation("pushing") --TODO: custom animation for this?
  end

  function state:on_finished()
    local hero = state:get_entity()
    hero:set_walking_speed(sol.main.global_constants.HERO_WALKING_SPEED)
    hero:set_animation("stopped")
    entity:drop_handle()
  end


  function state:on_position_changed()
    local pull_amount = 2 --watch out, a pull amount <2 can crash the game for some reason. Must be some math recursive overflow thing.
    local hero = state:get_entity()
    local current_distance = hero:get_distance(entity)
    hero:set_direction(hero:get_direction4_to(entity))

    --Move handle:
    state.handle:move_with_hero(hero)

    -- Check if we're going past the max length
    if current_distance > entity.max_length then
      -- Only restrict movement if it would increase the distance further
      -- Allow movement that maintains or decreases the distance
      local prev_pos = state.last_valid_position
      local x, y, z = hero:get_position()
      local ex, ey = entity:get_position()

      --Try putting the hero at the max allowable length from the box, at their current angle
      local h_angle = entity:get_angle(hero)
      local new_x = ex + math.cos(h_angle) * (entity.max_length - pull_amount)
      local new_y = ey + math.sin(h_angle) * (entity.max_length - pull_amount) * -1
      hero:set_position(new_x, new_y, z)

      --Check if we put the hero in a wall:
      if hero:test_obstacles() then
        --Put the hero at their last valid position instead
        if prev_pos then
          hero:set_position(prev_pos.x, prev_pos.y, prev_pos.z)
        else
          hero:set_position(x, y, z) --fallback incase we somehow didn't already have a previous valid position
        end
      end
      x, y, z = hero:get_position()
      state.last_valid_position = {x=x, y=y, z=z}

      --Also, trigger max length event:
      if entity.on_full_pull then entity:on_full_pull() end

    else
      --If we're not past max length, save the current hero position, in case we accidentally pull them into a wall later
      local x, y, z = hero:get_position()
      state.last_valid_position = {x=x, y=y, z=z}
    end

  end
  

  function state:on_command_pressed(cmd)
    local hero = state:get_entity()
    local handled = false
    if cmd == "attack" then
      hero:unfreeze()
      --Don't handle so the attack can propagate
    elseif cmd == "action" or cmd == "cancel" or cmd == "item_1" or cmd == "item_2" then
      hero:unfreeze()
      handled = true
    end
  end

  return state
end




function entity:on_created()
  entity.max_length = tonumber(entity:get_property("max_length") or 96)
  if entity:get_property("max_links") then entity.max_length = tonumber(entity:get_property("max_links") * 8) end --can set length property directly, or by specifying number of links
  entity.retract_speed = tonumber(entity:get_property"retract_speed" or 60)
  entity:set_traversable_by(true)
  entity:set_drawn_in_y_order(true)
  entity.chain_links = {}
  entity.chain_length = 0 --updated every 4px or so
  entity.abs_chain_length = 0 --true length, very noisy

  --Create handle:
  local direction = entity:get_direction()
  local x, y, z = entity:get_position()
  local hx, hy, hz = x, y, z
  hx = x + game:dx(8)[direction]
  hy = y + game:dy(8)[direction]

  local handle = map:create_custom_entity({
    x = hx, y = hy, layer = hz, direction = 0,
    width = 16, height = 16,
    sprite = "world_objects/pull_chain/handle",
    --model = "world_objects/pull_chain/handle",
  })
  handle:set_origin(8,8)
  local handle_sprite = handle:get_sprite()
  handle_sprite:set_rotation(entity:get_angle(handle))
  handle:set_traversable_by(false)
  handle:set_traversable_by("hero", function(handle, e) return handle:overlaps(e) end)
  handle:set_traversable_by("enemy", function(handle, e) return handle:overlaps(e) end)
  handle:set_can_traverse("hero", true)
  handle.home_x = hx
  handle.home_y = hy
  handle.can_conduct_electricity = true
  handle.can_traverse_chain_link = true

  function handle:on_interaction()
    handle:start_carried()
  end

  function handle:start_carried()
    local m = handle:get_movement()
    if m then m:stop() end
    local hero = map:get_hero()
    local state = entity:get_pulling_state()
    state.handle = handle
    hero:start_state(state)
  end

  function handle:move_with_hero()
    local hero = map:get_hero()
    local angle = hero:get_angle(entity)
    local ox, oy, z = hero:get_position()
    local distance = hero:get_distance(entity)

    --Move handle:
    local hx = ox + math.cos(angle) * 8
    local hy = oy - math.sin(angle) * 8
    entity.handle:set_position(hx, hy, z)
    entity.handle:get_sprite():set_rotation(entity:get_angle(hero))

    entity:update_chain_links()
  end

  entity.handle = handle
  handle.box = entity
end



--Move the chain in/out to match the location of the handle
function entity:update_chain_links()
  local handle = entity.handle
  local distance = handle:get_distance(entity)
  local previous_num_links = #entity.chain_links
  local num_links = math.floor(distance / LINK_SIZE)
  local angle = handle:get_angle(entity)
  local ox, oy, z = handle:get_position()

  --Remove links if needed:
  if previous_num_links > num_links then
    entity.chain_links[#entity.chain_links]:remove()
    entity.chain_links[#entity.chain_links] = nil
  end
  --Make sound if adding or removing link:
  if (previous_num_links ~= num_links) and (math.abs(entity.chain_length - distance) > 4) then
    entity:update_length(num_links, num_links > previous_num_links and 1 or -1)
    entity.chain_length = distance
  end

  for i = 1, num_links do
    local x = ox + (math.cos(angle) * (LINK_SIZE * i))
    local y = oy - (math.sin(angle) * (LINK_SIZE * i))
    if entity.chain_links[i] then
      entity.chain_links[i]:set_position(x, y, z)
    else
      local link = map:create_custom_entity{
        x=x, y=y, layer=z, width=8, height=8, direction=0,
        sprite = "world_objects/pull_chain/link",
      }
      link:set_origin(4,4)
      link:set_traversable_by(false)
      link:set_traversable_by("hero", function(link, other)
        local s, so = other:get_state()
        return other:overlaps(link) or (so and so:get_description() == "chain_pulling")
      end)
      link:set_traversable_by("custom_entity", function(link, other) return other.can_traverse_chain_link end)
      link.can_conduct_electricity = true
      entity.chain_links[i] = link
    end
  end

  if entity.on_length_changed then entity:on_length_changed(distance, distance > entity.abs_chain_length and 1 or -1) end
  entity.abs_chain_length = distance
end


function entity:drop_handle()
  local m = sol.movement.create"target"
  local handle = entity.handle
  handle.pull_chain_handle_can_be_caught = true
  m:set_target(handle.home_x, handle.home_y)
  m:set_speed(entity.retract_speed)
  m:set_ignore_obstacles(true)
  m:start(handle, function()
    local sprite = handle:get_sprite()
    sprite:set_rotation(entity:get_angle(handle))
    sol.audio.play_sound("impact_metal")
    entity:update_length(0, -1)
  end)

  function m:on_position_changed()
    entity:update_chain_links()
  end
end


function entity:update_length(num_links, direction)
  local sprite = entity:get_sprite()
  local animation = direction == 1 and "spin" or "spin_reverse"
  sprite:set_animation(animation, function() sprite:set_animation("stopped") end)
  sol.audio.play_sound("impact_metal_2")
  if entity.on_links_changed then entity:on_links_changed(num_links, direction) end
end



