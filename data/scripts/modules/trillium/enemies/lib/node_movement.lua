--[[
Created by Max Mraz, license MIT
To apply this behavior to trillium enemies, set the entity property "idle_movement_type" to "node"
Then set a property called "pathfinding_node_prefix" to a prefix of entities on the map, which will serve as nodes.
Nodes can be custom entites or sensors or something- as long as the enemy can walk over them.
They should not have obstacles between them, and should have suffixes like _1, _2, etc.
So for example, to have an enemy follow a path, place entities named "enemy_route_a_1", "enemy_route_a_2", "enemy_route_a_3", etc.
WARNING: route prefixes must not contain numbers. The only numbers allowed in node names are the node numbers.
For example "route_3_1", "route_3_2" would be invalid, both would be considered the first node on the same route.
Then you'd set "idle_movement_type" to "node", and "pathfinding_node_prefix" to "enemy_route_a"

Pausing: you can set the property "pause_duration" on a node. If this exists, enemies along this route with pause when they reach this node for the given duration.

Multiple enemies can follow the same route. Enemies will always first walk to the closest node, then proceed numerically.
There can be multiple routes on the same map, they will just need different prefixes. Such as "enemy_route_a" and "enemy_route_b", etc.

NOTE: this has a limitation that paths must loop.
If an enemy walks to the final node, it will then try to reach node 1, rather than traversing backward along the route.
WARNING: route prefixes must not contain numbers. The only numbers allowed in node names are the node numbers.
--]]

local manager = {}

function manager.apply_behavior(enemy)
  local game = enemy:get_game()
  local map = enemy:get_map()

  function enemy:find_closest_node_number()
    local x, y, z = enemy:get_position()
    local closest_node
    local distance
    local prefix = enemy:get_property("pathfinding_node_prefix")
    assert(prefix ~= nil, "Enemy must have a a pathfinding_node_prefix property to use node movement type")
    for node in map:get_entities(prefix) do
      if not distance then
        closest_node = node
        distance = enemy:get_distance(node)
      elseif enemy:get_distance(node) < distance then
        closest_node = node
        distance = enemy:get_distance(node)
      end
    end
    local node_number = closest_node:get_name():match("%d+")
    return node_number
  end

  function enemy:go_next_node()
    local prefix = enemy:get_property("pathfinding_node_prefix")
    local m = sol.movement.create("target")
    m:set_speed(enemy.node_movement_speed or enemy.idle_movement_speed + 10 or 40)
    local target = map:get_entity(prefix .. "_" .. enemy.node_movement_target_node_number)
    m:set_target(target)
    m:start(enemy, function()
      if map:has_entity(prefix .. "_" .. enemy.node_movement_target_node_number + 1) then
        enemy.node_movement_target_node_number = enemy.node_movement_target_node_number + 1
      else
        enemy.node_movement_target_node_number = 1
      end
      local pause_duration = tonumber(target:get_property("pause_duration")) or 0
      if pause_duration > 0 then enemy:get_sprite():set_animation"stopped" end
      sol.timer.start(enemy, pause_duration, function()
        if pause_duration > 0 then enemy:get_sprite():set_animation"walking" end
        enemy:go_next_node()
      end)
    end)
  end


  function enemy:start_node_movement()
    if not enemy.node_movement_target_node_number then
      enemy.node_movement_target_node_number = enemy:find_closest_node_number()
    end
    enemy:go_next_node()
  end


end

return manager