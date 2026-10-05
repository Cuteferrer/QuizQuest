local enemy_meta = sol.main.get_metatable"enemy"


enemy_meta:register_event("on_hurt", function(self, attack)
  local enemy = self
  local game = enemy:get_game()
  if attack == "explosion" then
    enemy:remove_life(game:get_value("explosion_damage") or 10)
  end
end)


--Animation for falling in hole or deep water:
enemy_meta:register_event("on_position_changed", function(enemy)
  local ground = enemy:get_ground_below()
  local behavior = enemy:get_obstacle_behavior()
  if ground == "deep_water" and behavior == "normal" then
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    enemy:fall_in_water()

  elseif ground == "hole" and behavior ~= "flying" then
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    enemy:fall_down_hole()

  end
end)


function enemy_meta:immobilize(duration)
  local enemy = self
  local sprite = enemy:get_sprite()
  local map = enemy:get_map()

  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  if sprite:has_animation"immobilized" then
    sprite:set_animation"immobilized"
  elseif sprite:has_animation"stopped" then
    sprite:set_animation"stopped"
  elseif sprite:has_animation"walking" then
    sprite:set_animation"walking"
  end

  if enemy.on_immobilized then enemy:on_immobilized() end

  sol.timer.start(map, duration or 3000, function()
    enemy:restart()
  end)
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


--Get Sprite overwrite to default to "main" sprite
local old_get_sprite = enemy_meta.get_sprite
function enemy_meta:get_sprite(sprite_name)
  local enemy = self
  local potential_main_sprite
  if not sprite_name then
    potential_main_sprite = old_get_sprite(enemy, "main")
  end
  return potential_main_sprite or old_get_sprite(enemy, sprite_name)
end


function enemy_meta:set_has_shadow(has_shadow, size)
  local enemy = self
  if not has_shadow then has_shadow = true end
  if not size then size = "medium" end
  assert(type(has_shadow) == "boolean", "enemy:set_has_shadow() - argument 1 must be a boolean" )
  if has_shadow then
    local sprite = enemy:create_sprite("shadows/shadow_" .. size, "shadow")
    sprite:set_direction(0)
    enemy:bring_sprite_to_back(sprite)
  else
    enemy:remove_sprite(enemy:get_sprite"shadow")
  end
end


enemy_meta:register_event("on_dead", function(self)
  local enemy = self
  local game = enemy:get_game()
  --Trigger charm event
  game.event_manager:trigger_event("on_enemy_killed", enemy)

  --Check for doors to open
  local open_doors_prefix = enemy:get_property("open_doors_prefix")
  if open_doors_prefix then
    enemy:get_map():open_doors(open_doors_prefix)
  end

  --Trigger a map event if all enemies in a group are killed
  local enemy_group = enemy:get_property("group")
  if enemy_group then
    local map = enemy:get_map()
    local still_alive = false
    for e in map:get_entities_by_type"enemy" do
      if (e:get_property("group") == enemy_group) and e:get_life() > 0 then
        still_alive = true
      end
    end
    if not still_alive and map.on_enemy_group_dead then
      map:on_enemy_group_dead(enemy_group)
    end
  end
end)


--For a boss, call this function in their on_dying event.
function enemy_meta:boss_death(animation_id)
  local enemy = self
  local map = enemy:get_map()
  local x, y, z = enemy:get_position()
  local enemy_breed = enemy:get_breed()
  local dummy = enemy:start_boss_death_animation(animation_id)
  map:create_poof(x, y, z, "enemies/enemy_killed_big")
  map:screenshake{ shake_count = 25}
  enemy:on_dead()
  if map.on_boss_dead then map:on_boss_dead(enemy_breed) end
end


function enemy_meta:start_boss_death_animation(animation_id)
  local enemy = self
  local map = enemy:get_map()
  local enemy_breed = enemy:get_breed()
  local enemy_sprite = enemy:get_sprite()
  local direction = enemy_sprite:get_direction()
  --this should be impossible, but it happened, so we'll check for it:
  if direction > (enemy_sprite:get_num_directions() - 1) then direction = 0 end
  local x, y, z = enemy:get_position()
  local width, height = enemy_sprite:get_size()

  sol.audio.play_sound("boss_fade")
  local dummy = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = enemy_sprite:get_animation_set(),
  }
  enemy:remove()
  local dummy_sprite = dummy:get_sprite()
  dummy_sprite:set_direction(direction)
  dummy:set_drawn_in_y_order(true)
  if animation_id then dummy_sprite:set_animation(animation_id) end
  dummy_sprite:fade_out(80)
  local em = map:create_particle_emitter(x, y, z)
  em.shape = "circle"
  em.target = dummy
  em.particle_sprite = "effects/blood_drop"
  em.particle_color = {30, 0, 20}
  em.particle_opacity = {180,250}
  em.particle_speed = 90
  em.particle_distance = 128
  em.duration = 2000
  em:emit()
  local em_2 = map:create_particle_emitter(x, y, z)
  em_2.duration = 2500
  em_2.width = width - 16
  em_2.particle_opacity = {50,150}
  em_2.color = {190,190,180}
  em_2.angle_variance = 0
  em_2:emit()
  sol.timer.start(map, em.duration, function()
    dummy:remove()
  end)
  return dummy
end

