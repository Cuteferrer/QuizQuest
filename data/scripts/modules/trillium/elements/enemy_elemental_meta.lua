local enemy_meta = sol.main.get_metatable"enemy"

--Fire Reactions:
function enemy_meta:react_to_fire(fire)
  local enemy = self
  if  not enemy.fire_immunity then
    if enemy.process_hit then
      enemy:process_hit({damage = fire.damage or 2, damage_type = "fire", stagger_value = 0})
    else
      enemy:hurt(fire.damage or 2)
    end
    if enemy.flammable then
      enemy:start_status_effect("burn")
    elseif enemy.build_up_status_effect then
      enemy:build_up_status_effect("burn", 15)
    end
  end
end


--Ice Reactions:
function enemy_meta:react_to_ice(ice)
  local enemy = self
  if not enemy.ice_immunity then
    if enemy.process_hit then
      enemy:process_hit({damage = ice.damage or 2, damage_type = "ice", stagger_value = 0})
    else
      enemy:hurt(ice.damage or 2)
    end
  end
  if enemy.build_up_status_effect then
    enemy:build_up_status_effect("cold", 20)
  end
end


--Lightning Reactions:
function enemy_meta:react_to_lightning(lightning)
  local enemy = self
  if not enemy.lightning_immunity and enemy:is_visible() then
    if enemy.process_hit then
      enemy:process_hit({damage = lightning.damage or 3, damage_type = "lightning", stagger_value = lightning.stagger_value or 45})
    else
      enemy:hurt(lightning.damage or 3)
    end
    --If hit again while in the shock status, proc a whole bunch of lightning damage
    if enemy:is_status_effect_active("shock") then
      local map = enemy:get_map()
      local num_hits = 7
      local i = 0
      sol.timer.start(map, 60, function()
        enemy:process_hit({damage = (lightning.damage or 20)/2, damage_type = "lightning", stagger_value = lightning.stagger_value or 45})
        i = i + 1
        return i < num_hits
      end)
      enemy:stop_status_effect("shock")
    end
  end
end

function enemy_meta:react_to_lightning_bolt(lightning)
  local enemy = self
  if not enemy.lightning_immunity then
    if enemy.process_hit then
      enemy:process_hit({damage = lightning.damage or 16, damage_type = "lightning", stagger_value = lightning.stagger_value or 45})
    else
      enemy:hurt(lightning.damage or 16)
    end
    enemy:react_to_fire(lightning)
    if enemy.build_up_status_effect then
      enemy:build_up_status_effect("burn", 95)
    end
  end
end
