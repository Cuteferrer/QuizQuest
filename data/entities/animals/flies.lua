local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local min_flies, max_flies = 2, 5
local min_radius, max_radius = 8, 24
local flies = {}

function entity:on_created()
  local num_flies = math.random(min_flies, max_flies)
  for i = 1, num_flies do
    local fly = entity:create_sprite("animals/fly")
    fly:set_xy(0, math.random(1,6) + 4 * num_flies * -1)
    local m = sol.movement.create"circle"
    m:set_radius(math.random(min_radius, max_radius))
    m:set_clockwise(math.random(1, 2) == 2)
    m:set_angle_from_center(math.rad(math.random(1,360)))
    m:start(fly)
    flies[i] = fly
  end
end
