--An entity to adjust the hero's position when they're falling from a higher layer
--Place over south facing walls, for example

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_visible(false)
  entity:set_property("unstable_floor", "true")
  entity:add_collision_test("origin", function(entity, other)
    if other:get_type() == "hero" and not entity.moving_hero then
      local hero = other
      if not hero:is_directly_atop(entity) then return end
      local state, state_ob = hero:get_state()
      if state == "custom" then state = state_ob:get_description() end
      if (state == "free") or (state == "falling") or (state == "walking") or (state == "dash_recovery") then
        entity.moving_hero = true
        local state = entity:get_state()
        hero:start_state(state)
        -- hero:set_animation"jumping_down"
        local direction = entity:get_direction()
        local x1, y1, width, height  = entity:get_bounding_box()
        local x2 = x1 + width
        local y2 = y1 + height
        local hx, hy = hero:get_position()
        local dx, dy = 0, 0
        --print("Direction:", direction, "x1, y1", x1, y1, "x2, y2", x2, y2, "hx, hy", hx, hy)
        --distance between edge of entity and hero, plus some for hero to clear the bottom
        if direction == 0 then dx = x2 - hx + 13
        elseif direction == 1 then dy = hy - y1 - 13
        elseif direction == 2 then dx = hx - x1 - 13
        elseif direction == 3 then dy = y2 - hy + 13
        end
        --print("dx:", dx, "dy:", dy, "distance:", dx + dy)
        local m = sol.movement.create"straight"
        m:set_angle(direction * math.pi / 2)
        m:set_speed(300)
        m:set_max_distance(dx + dy)
        m:set_ignore_obstacles(true)
        m:start(hero, function()
          hero:set_animation("landing", function() hero:set_animation"stopped" end)
          hero:unfreeze()
        end)
      end
    end
  end)
end

function entity:get_state()
  local hero = game:get_hero()
  local state = sol.state.create("z_adjust_falling")
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

  function state:on_started()
  end

  function state:on_finished()
    entity.moving_hero = false
  end

  return state
end
