local enemy_meta = sol.main.get_metatable("enemy")

function enemy_meta:has_los(entity) 
  local los = true
  local map = self:get_map()
  local x, y, z = self:get_position()
  local dx, dy = 0, 0
  local distance = self:get_distance(entity)
  local angle = self:get_angle(entity)
  local facing_x, facing_y, _ = self:get_facing_position()
  local facing_dir = self:get_sprite():get_direction()
  local dir_to_hero = self:get_facing_direction_to(entity)
  if entity:get_layer() ~= z then return false end --if you're not on the same layer, no LOS
  for i=0, distance do
    if entity:get_layer() ~= self:get_layer() then
      los = false
      break
    end
    dx, dy = math.floor(math.cos(angle)*i), -math.floor(math.sin(angle)*i)
    if (facing_dir ~= dir_to_hero) and not self.alert_all_directions then
      los = false
      break
    else
      local obstacle = self:test_obstacles(dx, dy)
      if obstacle then
        --If we've hit an obstacle, then double check it's not water or a hole before saying there's no LOS
        local ground = map:get_ground(x + dx, y + dy, z)
        if (ground ~= "deep_water") and (ground ~= "shallow_water") and (ground ~= "hole") and (ground ~= "lava") and (ground ~= "traversable") then
          --note: added a check for ground ~= traversable, because LOS was hitting obstacles, but the ground there was traversable. This might have been a bad change. Entities won't block LOS anymore...
          los = false
          break
        end
      end
    end
  end
  return los
end


function enemy_meta:is_on_screen()
  local enemy = self
  local map = enemy:get_map()
  local camera = map:get_camera()
  local camx, camy = camera:get_position()
  local camwi, camhi = camera:get_size()
  local enemyx, enemyy = enemy:get_position()

  local on_screen = enemyx >= camx and enemyx <= (camx + camwi) and enemyy >= camy and enemyy <= (camy + camhi)
  return on_screen
end
