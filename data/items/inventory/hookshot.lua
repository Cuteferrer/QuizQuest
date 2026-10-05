local item = ...
local game = item:get_game()

local config = require("items/inventory/library/hookshot_config.lua")
local hookshot_manager = require("items/inventory/library/hookshot_manager.lua")

function item:on_started()
  item:set_savegame_variable("possession_hookshot")
  item:set_assignable(true)
end


function item:on_using()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()

  local state, state_ob = hero:get_state()
  if state_ob and (state_ob:get_description() == "hookshot_casting" or state_ob:get_description() == "hookshot") then
    return
  end

  local hook = item:create_hook()
  hook:set_visible(false)
  item.hook = hook
  hero:start_state(item:get_casting_state())
  hero:set_animation"hookshot"
  local m = sol.movement.create"straight"
  m:set_angle(hero:get_direction() * math.pi / 2)
  m:set_speed(config.speed)
  m:set_max_distance(config.distance)
  m:set_smooth(false)
  sol.audio.play_sound("bow")
  sol.timer.start(hero, 200, function() --slight delay to match animation
    hook:set_visible(true)
    m:start(hook, function() item:retract_hook() end)
  end)
  function m:on_obstacle_reached()
    if not item:check_for_nearby_targets(hook) then
      item:retract_hook()
      sol.audio.play_sound"sword_tapping"
    end
  end

end


function item:is_entity_hookable(entity)
  local hookable = false
  if entity.hookshot_target or entity:get_property"hookshot_target"
  or (entity.is_hookable and entity:is_hookable()) then
    hookable = true
  end
  return hookable
end


function item:check_for_nearby_targets(hook)
  --This function is because, somehow, the hook's movement can hit an obstacle without the "touching" or "sprite" collisions registering.
  --This usually happens when the hook is too far off-axis of the target
  local range = 5
  local map = hook:get_map()
  local found_target = false
  local x, y, z = hook:get_position()
  local candidates = {}
  --Find all potential targets in range:
  for entity in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
    if item:is_entity_hookable(entity) then
      candidates[entity] = entity
    end
  end
  --[[ This would snap align the hook to the target's origin, but it causes some issues with sliding the hero around at the end of the movement:
  --Choose closest target:
  local candidate
  for _, entity in pairs(candidates) do
    if candidate == nil then
      candidate = entity
    else
      if entity:get_distance(hook) < candidate:get_distance(hook) then
        candidate = entity
      end
    end
  end
  if candidate then
    found_target = true
    local dir4 = hook:get_movement():get_direction4()
    local horiz_align = ((dir4 == 0) or (dir4 == 2)) and true or false
    if horiz_align then --align hook to y axis of target
      local tx, ty = candidate:get_position()
      hook:set_position(x, ty, z)
    else
      local tx, ty = candidate:get_position()
      hook:set_position(tx, y, z)
    end
    item:pull_hero(hook)
  end
  --]]
  if next(candidates) ~= nil then --make sure there are nearby targets
    found_target = true
    item:pull_hero(hook)
  end

  return found_target
end


function item:retract_hook()
  local hero = game:get_hero()
  local hook = item.hook
  hook:clear_collision_tests()
  if hook:get_distance(hero) <= 16 then
    item:unhook()
    return
  end
  sol.timer.start(hook, config.slack_delay or 120, function() item.rope_sprite:set_animation"rope_slack" end)
  local m = sol.movement.create"straight"
  m:set_max_distance(hook:get_distance(hero))
  m:set_angle(hook:get_angle(hero))
  m:set_ignore_obstacles(true)
  m:set_speed(config.speed)
  m:start(hook, function()
    item:unhook()
  end)
  sol.timer.start(hero, 2500, function()
    if hook:exists() then
      item:unhook()
    end 
  end)
end


function item:pull_hero(hook)
  local hero = game:get_hero()
  if hero:get_distance(hook) <=8 then --can't hook if you're already next to the target
    item:unhook()
    return
  end
  --Stop hook:
  hook:stop_movement()
  hook:clear_collision_tests()
  sol.audio.play_sound"arrow_hit"
  --Pull hero:
  local state = item:get_hookshot_state()
  local current_state, current_state_ob = hero:get_state()
  if current_state == "custom" and (current_state_ob == state) then --Already being pulled
    return
  end
  hero:set_animation"hookshot_pulling"
  sol.timer.start(hook, config.slack_delay or 120, function() item.rope_sprite:set_animation"rope_slack" end)
  hero:start_state(state)
  local previous_positions = {}
  previous_positions[1] = {hero:get_position()}
  local x, y, z = hook:get_position()
  y = y - (hook.direction_offset_y or 0)
  local m = sol.movement.create"straight"
  m:set_max_distance(hero:get_distance(hook))
  m:set_angle(hero:get_angle(x, y))
  m:set_speed(config.speed)
  m:set_smooth(true)
  m:start(hero, function()
    item:unhook()
  end)
  function m:on_obstacle_reached()
    item:unhook()
  end
  function state:on_position_changed()
    previous_positions[#previous_positions + 1] = {hero:get_position()}
  end
  function state:on_finished()
    if item:test_obstacles_below(hero:get_position()) then
      --iterate backward through previous_positions until a safe one is found
      local safe_position = previous_positions[1] --we know the starting one is safe
      for i = #previous_positions, 1, -1 do
        local x, y, z = previous_positions[i][1],previous_positions[i][2],previous_positions[i][3] 
        local is_obstacle = item:test_obstacles_below(x, y, z)
        if not is_obstacle then
          safe_position = {x, y, z} break
        end
      end
      sol.timer.start(hero, 50, function()
        hero:set_position(safe_position[1], safe_position[2], safe_position[3])
        hero:set_blinking(true, 200)
      end)
    end
  end
end


function item:catch_entity(entity)
  local hook = item.hook
  local hero = game:get_hero()
  local is_enemy = entity:get_type() == "enemy"
  hook:register_event("on_position_changed", function()
    if not is_enemy or entity:get_distance(hero) > 24 then
      if not entity:exists() then return end
      entity:set_position(hook:get_position())
    end
  end)
end


function item:create_hook()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  local hook_direction_offset_x = {[0]=0, [1]=0, [2]=0, [3]=0}
  local hook_direction_offset_y = {[0]=-8, [1]=0, [2]= -8, [3]=0}
  local hook = map:create_custom_entity{
    x=x, y= y + hook_direction_offset_y[direction], layer=z,
    direction = 0,
    width = 8, height=8, sprite="items/hookshot"
  }
  hook.direction_offset_x = hook_direction_offset_x[direction]
  hook.direction_offset_y = hook_direction_offset_y[direction]
  hook:set_origin(4, 4)
  local hook_sprite = hook:get_sprite()
  hook_sprite:set_rotation(direction * math.pi / 2)
  hook_sprite:set_animation"hook"
  hook:set_drawn_in_y_order(true)
  hook:set_can_traverse_ground("hole", true)
  hook:set_can_traverse_ground("deep_water", true)
  hook:set_can_traverse_ground("shallow_water", true)
  hook:set_can_traverse_ground("lava", true)
  hook:set_can_traverse_ground("prickles", true)
  hook:set_can_traverse_ground("low_wall", true) --TODO: eh? eh? Maybe? What happens with this?
  hook:set_can_traverse("hero", true)
  hook:set_can_traverse("crystal", true)
  hook:set_can_traverse("jumper", true)
  hook:set_can_traverse("stairs", true)
  hook:set_can_traverse("stream", true)
  hook:set_can_traverse("switch", true)
  hook:set_can_traverse("teletransporter", true)

  local direction_offset_x = {[0]=0, [1]=1, [2]=1, [3]=1}
  local direction_offset_y = {[0]=-6, [1]=-2, [2]=-5, [3]=-2}
  local rope_sprite = hook:create_sprite"items/hookshot"
  rope_sprite:set_scale(.1, 1)
  item.rope_sprite = rope_sprite
  rope_sprite:set_animation"rope_taut"
  rope_sprite:set_transformation_origin(0,1)
  --rope_sprite:set_xy(0, direction_offset_y[direction])
  function hook:on_pre_draw()
    local rope_length = 96
    rope_sprite:set_scale((hook:get_distance(hero) - 4) / rope_length, 1)
    local hx, hy = hero:get_position()
    rope_sprite:set_rotation(hook:get_angle(hx, hy - 8))
  end

  --Collision with entities
  local function collision_test(hook, entity)
    local entity_type = entity:get_type()

    --Pull to targets:
    if item:is_entity_hookable(entity) then
      item:pull_hero(hook)

    --Catch and pull to hero:
    elseif entity.hookshot_catchable or entity:get_property"hookshot_catchable"
    or (entity.is_catchable_with_hookshot and entity.is_catchable_with_hookshot()) then
      item:catch_entity(entity)
      hook:stop_movement()
      hook:clear_collision_tests()
      item:retract_hook()
    elseif entity.react_to_hookshot then
      entity:react_to_hookshot(hook, hero)

    --Hit enemies:
    elseif entity:get_type() == "enemy" then
      local enemy = entity
      sol.audio.play_sound"enemy_hurt"
      hook:stop_movement()
      hook:clear_collision_tests()
      local dist = enemy:get_distance(hero)
      if enemy.stagger then
        enemy:stagger(dist / config.speed * 1000 + config.stun_length)
      end
      if not enemy.weight or enemy.weight >= (game.hookshot_pull_weight or 10) then --here's where enemy weight is set to determine pull/drag
        item:pull_hero(hook)
      else
        item:catch_entity(enemy)
        item:retract_hook()
      end
    end
  end

  hook:add_collision_test("touching", function(hook, entity)
    if entity:get_type() == "hero" then return end
    collision_test(hook, entity)
  end)
  hook:add_collision_test("sprite", function(hook, entity, h_sprite, e_sprite)
    if entity:get_type() == "hero" then return end
    if hook_sprite ~= h_sprite then return end
    collision_test(hook, entity)
  end)

  --testing a bug:
print("Adding sprite test:")
  hook:add_collision_test("sprite", function(hook, entity)
    if entity:get_type() == "hero" then return end
    if entity:get_type() == "block" then print("hit block sprite collision") end
    --etc, code to pull you to block, etc
  end)
  --testing a bug:
print("Adding touching test:")
  hook:add_collision_test("touching", function(hook, entity)
    if entity:get_type() == "hero" then return end
    if entity:get_type() == "block" then print("hit block touching collision") end
    --etc, code to pull you to block, etc
  end)

  --Special test for some entities
  hook:add_collision_test("overlapping", function(hook, entity)
    if entity:get_type() == "hero" then return end
    local entity_type = entity:get_type()
    if entity_type == "crystal" then
      hook:clear_collision_tests()
      item:retract_hook()
      sol.audio.play_sound("switch")
      map:change_crystal_state()
    elseif entity_type == "switch" then
      if entity:is_walkable() then return end
      hook:clear_collision_tests()
      item:retract_hook()
      sol.audio.play_sound("switch")
      if entity:is_activated() then
        entity:set_activated(false)
        if entity.on_inactivated then entity:on_inactivated() end
      else
        entity:set_activated(true)
        if entity.on_activated then entity:on_activated() end
      end
    else
      collision_test(hook, entity)
    end
  end)

  return hook
end


function item:unhook()
  local hero = game:get_hero()
  local hook = item.hook
  hook:remove()
  hero:unfreeze() --to end hookshot state
end



function item:get_damage()
  local damage
  damage = game:get_value"hookshot_damage" or 2
  return damage
end


function item:test_obstacles_below(x, y, z)
  local map = game:get_map()
  local hero = game:get_hero()
  local hx, hy, hz = hero:get_position()
  if hero:test_obstacles(x - hx, y - hy, z - hz) then
    return true
  elseif map:get_ground(x, y, z) == "empty" and (map:get_min_layer() > z) then
    return item:test_obstacles_below(x, y, z - 1)
  else
    return false
  end
end


local casting_state = sol.state.create("hookshot_casting")
casting_state:set_can_control_direction(false)
casting_state:set_can_control_movement(false)
casting_state:set_can_be_hurt(true)
casting_state:set_can_use_sword(false)
casting_state:set_can_use_item(false)
casting_state:set_can_interact(false)
casting_state:set_can_grab(false)
casting_state:set_can_push(false)
casting_state:set_can_pick_treasure(true)
casting_state:set_can_use_teletransporter(false)
casting_state:set_can_use_switch(false)
casting_state:set_can_use_stream(false)
casting_state:set_can_use_stairs(false)
casting_state:set_can_use_jumper(false)
casting_state:set_carried_object_action("throw")

function item:get_casting_state()
  return casting_state
end

local hookshot_state = sol.state.create("hookshot")
hookshot_state:set_can_control_direction(false)
hookshot_state:set_can_control_movement(false)
hookshot_state:set_can_traverse_ground("hole", true)
hookshot_state:set_can_traverse_ground("deep_water", true)
hookshot_state:set_can_traverse_ground("lava", true)
hookshot_state:set_affected_by_ground("hole", false)
hookshot_state:set_affected_by_ground("deep_water", false)
hookshot_state:set_affected_by_ground("lava", false)
hookshot_state:set_gravity_enabled(false)
hookshot_state:set_can_come_from_bad_ground(false)
hookshot_state:set_can_be_hurt(false)
hookshot_state:set_can_use_sword(false)
hookshot_state:set_can_use_item(false)
hookshot_state:set_can_interact(false)
hookshot_state:set_can_grab(false)
hookshot_state:set_can_push(false)
hookshot_state:set_can_pick_treasure(true)
hookshot_state:set_can_use_teletransporter(false)
hookshot_state:set_can_use_switch(false)
hookshot_state:set_can_use_stream(false)
hookshot_state:set_can_use_stairs(false)
hookshot_state:set_can_use_jumper(false)
hookshot_state:set_carried_object_action("throw")

function item:get_hookshot_state()
  return hookshot_state
end
