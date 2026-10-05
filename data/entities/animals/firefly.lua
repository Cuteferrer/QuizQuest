local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("hole", true)
  local animation_set = entity:get_sprite():get_animation_set()
  entity:remove_sprite()
  entity:create_sprite(animation_set, "main")
  entity:set_drawn_in_y_order(true)
  local shadow_sprite = entity:create_sprite"shadows/shadow_small"
  entity:bring_sprite_to_back(shadow_sprite)

  entity:start_firefly_movement()
  entity:start_glow()
end



function entity:start_firefly_movement()
  local tether_distance = 96
  local speed = 10
  local x, y, z = entity:get_position()

  local function go_random()
    local m = sol.movement.create"random"
    m:set_speed(speed)
    m:start(entity)
  end

  local function go_home()
    entity:stop_movement()
    local m = sol.movement.create("straight")
    m:set_angle(entity:get_angle(x, y, z))
    m:set_speed(speed)
    m:start(entity)
    sol.timer.start(entity, 2500, function()
      go_random()
    end)
  end

  local function is_too_far()
    local dist = entity:get_distance(x, y, z)
    return dist > tether_distance
  end

  sol.timer.start(entity, 2000, function()
    if is_too_far() then go_home() end
    return true
  end)

  go_random()
end


function entity:start_glow()
  map:register_light_source(entity, "candle")
end



