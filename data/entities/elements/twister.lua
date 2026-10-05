local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_size(24, 24)
  entity:set_origin(12, 16)
  entity:set_drawn_in_y_order(true)

  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("prickles", true)
  entity:set_can_traverse(true)

  local collided_entities = {}

  --Origin collision test
  entity:add_collision_test("origin", function(entity, other)
    if collided_entities[other] then return end
    collided_entities[other] = true
    sol.timer.start(entity, 500, function() collided_entities[other] = false end)
    if other:get_type() == "hero" then
      entity:on_collision_hero(other)
    end
  end)

  --Sprite collision test
  entity:add_collision_test("sprite", function(entity, other)
    if other:get_type() == "hero" then return end
    if collided_entities[other] then return end
    collided_entities[other] = true
    sol.timer.start(entity, 500, function() collided_entities[other] = false end)
    if other.react_to_wind then
      other:react_to_wind(entity)
    elseif other:get_type() == "custom_entity" then
      local model = other:get_model()
      if model == "elements/flame" or (model == "elements/smolder") then
        entity:on_collision_fire(other)
      end
    elseif other:get_type() == "enemy" then
      entity:on_collision_enemy(other)
    end
  end)
end


function entity:on_collision_hero(hero)
      local current_state, ob = hero:get_state()
      if current_state == "back to solid ground" then return end
      if current_state == "falling" then return end
      hero:start_state(entity:get_twister_state())
      hero:start_feather_jump(600, "twister_launch")
      sol.timer.start(hero, 300, function()
        local m = hero:get_movement()
        if m then hero:set_direction(m:get_direction4()) end
        hero:set_animation"double_jumping"
      end)
end


function entity:on_collision_fire(fire)
  fire:remove()
end


function entity:on_collision_enemy(enemy)
  --twisters do nothing to enemies by default - however you can overwrite this for any twister. For example, for those created by an item
end


function entity:set_duration(duration)
  local sprite = entity:get_sprite()
  local dissapation_length = sprite:get_num_frames("disappearing", 0) * sprite:get_frame_delay"disappearing"
  sol.timer.start(entity, math.max(duration - dissapation_length, 0), function()
    entity:get_sprite():set_animation("disappearing", function()
      entity:remove()
    end)
  end)
end


function entity:get_twister_state()
  local state = sol.state.create("twister_spinning")
  state:set_can_control_direction(false)
  state:set_can_control_movement(true)
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
  return state
end
