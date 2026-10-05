local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  entity:set_property("unstable_floor", "true")

  entity.frequency = entity:get_property"frequency" or 4000
  entity.init_delay = entity:get_property"init_delay" or 0
  entity.warning_duration = entity:get_property"warning_duration" or 300
  entity.hot_duration = entity:get_property("hot_duration") or 300
  entity.enemy_damage = entity:get_property("enemy_damage") or entity:get_property("damage") or 20
  entity.hero_damage = entity:get_property("hero_damage") or entity:get_property("damage") or 20

  entity:set_active(tobool(entity:get_property("active") or true))

  --Collision:
  entity.collided_entities = {}
  entity:add_collision_test("overlapping", function(entity, other)
    if not entity.venting then return end
    if entity.collided_entities[other] then return end
    entity.collided_entities[other] = true
    sol.timer.start(entity, 400, function() entity.collided_entities[other] = nil end)
    entity:burn_other(other)
  end)

  --Create emitters:
  --Emitter 1
  local x, y, z = entity:get_position()
  local em = map:create_particle_emitter(x, y, z, "burst")
  em.target = entity
  em.angle = math.pi / 2
  em.angle_variance = 0
  em.particle_sprite = "effects/smoke_particle"
  em.particle_speed = 20
  em.particles_per_loop = 10
  em.particle_lifetime = 2000
  em.particle_scaling = {1, 2.5}
  em.particle_color = {220, 230, 240}
  em.particle_opacity = {50,100}
  em.particle_fade_speed = 5
  em.remove_after_emitting = false
  entity.emitter_1 = em
  --emitter 2:
  em = map:create_particle_emitter(x, y, z, "burst")
  em.target = entity
  em.angle = math.pi / 2
  em.angle_variance = 0
  em.particle_sprite = "effects/smoke_clouds"
  em.particle_speed = 15
  em.particles_per_loop = 6
  em.particle_opacity = {100,255}
  em.particle_fade_speed = 5
  em.particle_animation_loops = false
  em.remove_after_emitting = false
  entity.emitter_2 = em
end


function entity:set_active(active)
  entity.active = active
  if active then
    entity:activate()
  else
    entity:deactivate()
  end
end


function entity:activate()
  entity.steam_timer = sol.timer.start(entity, entity.init_delay, function()
    entity:burst()
    return entity.frequency
  end)
end


function entity:deactivate()
  if entity.steam_timer then entity.steam_timer:stop() end
end


function entity:burst()
  if entity:get_distance(hero) > 500 then return end
  local sprite = entity:get_sprite()
  sprite:set_animation("warning")
  entity:make_sound("steam_woosh")

  if not entity:is_in_same_region(hero) then return end

  sol.timer.start(entity, entity.warning_duration, function()
    --Activate damage
    entity.venting = true
    sol.timer.start(entity, entity.hot_duration, function()
      entity.venting = false
    end)
    --Sound/Sprite:
    entity:make_sound("fireball")
    sprite:set_animation("deactivating", function() sprite:set_animation("inactive") end)
    --emitter:
    if entity:is_on_screen() then
      entity.emitter_1:emit()
      entity.emitter_2:emit()
    end
  end)

end


function entity:burn_other(other)
  if other:get_type() == "enemy" then
    other:process_hit({damage = entity.enemy_damage, damage_type = "fire"})
  elseif other:get_type() == "hero" then
    other:process_hit{
      damage = entity.hero_damage,
      damage_type = "fire",
      enemy = entity,
    }
  end
end
