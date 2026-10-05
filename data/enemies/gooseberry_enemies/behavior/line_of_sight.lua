local enemy_meta = sol.main.get_metatable("enemy")

function enemy_meta:has_los(entity) 

  local los = true
  local dx, dy = 0, 0
  local distance = self:get_distance(entity)
  local angle = self:get_angle(entity)
  local facing_x, facing_y, _ = self:get_facing_position()
  local facing_dir = self:get_direction4_to(facing_x, facing_y)
  local dir_to_hero = self:get_direction4_to(self:get_map():get_hero())
  for i=0, distance do
    dx, dy = math.floor(math.cos(angle)*i), -math.floor(math.sin(angle)*i)
    if facing_dir ~= dir_to_hero then
      los = false
      break
    else
      if self:test_obstacles(dx, dy) then
          los = false
          break
      end
    end
  end

  return los
end