local entity = ...
local game = entity:get_game()
local map = entity:get_map()


local corner_types = {
  [0] = "top_right",
  [1] = "top_left",
  [2] = "bottom_left",
  [3] = "bottom_right",
}

local dir_conversion_table = {
  top_right = {
    [0] = 3,
    [1] = 2,
    ["other"] = 2,
  },
  top_left = {
    [2] = 3,
    [1] = 0,
    ["other"] = 0,
  },
  bottom_left = {
    [3] = 0,
    [2] = 1,
    ["other"] = 0,
  },
  bottom_right = {
    [0] = 1,
    [3] = 2,
    ["other"] = 2,
  },
}



function entity:on_created()
  entity:set_visible(tobool(entity:get_property("visible")) or false)

  local current_vehicles = {}

  entity:add_collision_test("containing", function(entity, other)
    if other.is_track_vehicle and not current_vehicles[vehicle] then
      entity:redirect_cart(other)
      sol.timer.start(entity, 50, function()
        if not entity:overlaps(other) then
          current_vehicles[other] = nil
        else
          return true
        end
      end)
    end
  end)
end


function entity:redirect_cart(cart)
  cart:set_position(entity:get_position())
  local m = cart:get_movement()
  if m:get_speed() == 0 then return end --don't do anything if the cart isn't moving
  local dir = m:get_direction4()
  local corner_type = corner_types[entity:get_direction()]
  local new_dir = dir_conversion_table[corner_type][dir]
  --if new_dir == nil then new_dir = dir_conversion_table[corner_type]["other"] end --fallback in case you hit the corner going the wrong direction somehow
  if not new_dir then return end --If you're going a different direction, ignore the corner
  m:set_angle(math.pi / 2 * new_dir)
  m:start(cart)
  cart:set_direction(new_dir)
  sol.audio.play_sound("impact_metal_2")
  if cart.on_corner_redirect then
    cart:on_corner_redirect()
  end
end


function entity:spin(rot_dir)
  rot_dir = rot_dir or 1 --direction can be 1 (counter-clockwise) or -1 (clockwise)
  local current_direction = entity:get_direction()
  entity:set_direction((current_direction + rot_dir) % 4)
  entity:spark()
end


function entity:spark()
  local x, y, z = entity:get_position()
  local em = map:create_particle_emitter(x, y, z, "sparks")
  em.duration = 100
  em.particles_per_loop = 3
  em:emit()
  entity:make_sound("impact_metal_2")
end

