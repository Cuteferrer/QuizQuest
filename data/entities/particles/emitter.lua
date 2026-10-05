local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local timestep = 20 --how many ms the particles are recalculated


local function create_particle()
  local x, y, z = entity.target:get_center_position()
  if entity.target_offset then
    x = x + entity.target_offset[1]
    y = y + entity.target_offset[2]
  end
  if entity.shape == "circle" then
    x = x + math.cos(math.random(0, math.pi * 2)) * math.random(0, entity.width)
    y = y + math.sin(math.random(0, math.pi * 2)) * math.random(0, entity.width) * -1
  elseif entity.shape == "square" then
    x = x + math.random(entity.width * -1 / 2, entity.width / 2)
    y = y + math.random(-3, entity.height - 3) * -1
  end
  local angle = entity.angle + (math.random(entity.angle_variance * -1000, entity.angle_variance * 500) / 1000)
  local speed = entity.particle_speed + math.random(entity.particle_speed_variance * -1, entity.particle_speed_variance)
  local direction = math.random(0, entity.proto_sprite:get_num_directions() - 1)
  local opacity = math.random(entity.particle_opacity[1], entity.particle_opacity[2])
  local scale = math.random(entity.particle_scaling[1] * 100, entity.particle_scaling[2] * 100) / 100
  local rotation_angle = entity.particle_rotation and math.rad(math.random(1, 360)) or 0
  local rotation_speed = math.random(entity.particle_rotation_speed[1] * 1000, entity.particle_rotation_speed[2] * 1000) / 1000
  local rotation_direction = entity.particle_rotation == "clockwise" and 1 or -1
  if entity.particle_rotation == "random" then rotation_direction = (math.random(1,2) == 1) and 1 or -1 end
  return {
    x = x, y = y, layer = z,
    speed = speed,
    angle = angle,
    dx = speed * math.cos(angle),
    dy = speed * math.sin(angle) * -1,
    lifetime = entity.particle_lifetime,
    frame = 0,
    direction = direction,
    opacity = opacity,
    color = entity.particle_color,
    scale = scale,
    rotation_angle = rotation_angle,
    rotation_speed = rotation_speed,
    rotation_direction = rotation_direction,
  }
end


local function update_particles()
  entity.elapsed_time = (entity.elapsed_time or 0) + timestep
  entity.animation_frame_time = (entity.animation_frame_time or 0) + timestep
  local increment_frame = false
  if entity.particle_sprite_frame_delay and (entity.animation_frame_time >= entity.particle_sprite_frame_delay) then
    increment_frame = true
    entity.animation_frame_time = 0
  end

  for i = 1, #entity.particles do
    local particle = entity.particles[i]
    particle.lifetime = particle.lifetime - timestep
    if entity.particle_acceleration ~= 0 then
      particle.speed = particle.speed + (entity.particle_acceleration / 100)
      particle.dx = particle.speed * math.cos(particle.angle)
      particle.dy = particle.speed * math.sin(particle.angle) * -1
    end
    particle.x = particle.x + particle.dx * (timestep / 1000)
    particle.y = particle.y + particle.dy * (timestep / 1000)
    if increment_frame then
      local new_frame = particle.frame + 1
      if not entity.particle_animation_loops and (new_frame >= entity.particle_sprite_num_frames) then
        particle.lifetime = 0
      else
        particle.frame = new_frame % entity.particle_sprite_num_frames
      end
    end
    particle.opacity = particle.opacity - (entity.particle_fade_speed / 10)
    if particle.opacity <= 0 then particle.lifetime = 0 end
    if entity.particle_rotation then
      particle.rotation_angle = particle.rotation_angle + particle.rotation_speed * particle.rotation_direction
    end
    entity.particles[i] = particle --this should be redundant, I think, but just in case....
  end
  --Loop again to remove any particles past their lifetime (can't do it in one loop or it'll mess up the numbering)
  for i = 1, #entity.particles do
    if entity.particles[i] and (entity.particles[i].lifetime <= 0 ) then
      table.remove(entity.particles, i)
    end
  end
end


local function draw_particles()
  for i = 1, #entity.particles do
    local particle = entity.particles[i]
    local sprite = entity.proto_sprite
    sprite:set_direction(particle.direction)
    sprite:set_frame(particle.frame)
    sprite:set_color_modulation(particle.color)
    sprite:set_opacity(particle.opacity)
    sprite:set_scale(particle.scale, particle.scale)
    sprite:set_rotation(particle.rotation_angle)
    map:draw_visual(entity.proto_sprite, particle.x, particle.y)
  end
end


function entity:on_created()
  entity.particles = {}
  --Set default config:
  entity.target = entity --if the target is not the emitter itself, then it emits from the x/y of the target instead
  entity.target_offset = {0,0} --allow origin to be offset from target's origin
  entity.shape = "square"
  entity.width, entity.height = entity:get_size()
  entity.frequency = 10
  entity.angle = math.pi / 2
  entity.angle_variance = 2 * math.pi
  entity.particles_per_loop = 1 --can create multiple particles at once if every 10ms isn't fast enough
  entity.duration = nil --how long the emitter will last, nil means forever
  entity.remove_after_emitting = true --set to false if you plan to emit particles again
  entity.particle_sprite = "effects/particle_small"
  entity.particle_animation = nil --Leave nil for the default animation. NOTE: if there are multiple directions to the animation, a random one will be used per particle
  entity.particle_animation_loops = true
  entity.particle_lifetime = 1000
  entity.particle_speed = 100
  entity.particle_speed_variance = 20
  entity.particle_acceleration = 0 --not in any real unit, new_speed = speed + (acceleration / 100)
  entity.particle_color = {255, 255, 255}
  entity.particle_opacity = {255, 255} --range from lowest to highest opacity, assigned randomly
  entity.particle_fade_speed = (entity.particle_animation_loops and 15 or 0) --set to 0 and particles will not fade. Not in a real unit, particles fade by (fade speed / 10) opacity per update
  entity.particle_scaling = {1, 1} --specify min scale, max scale amount, for example {.8, 1.5}
  entity.particle_rotation = false --options are false (no rotation), true (starts at a random rotation), "clockwise" and "counterclockwise" (rotates as it moves), and "random" (either clockwise or counterclockwise)
  entity.particle_rotation_speed = { math.rad(5), math.rad(10)}

  --Draw particles when you draw this entity
  function entity:on_post_draw(camera)
    draw_particles()
  end

  --Automatically set a preset and start emitting
  if entity:get_property("type") then
    entity:set_preset(entity:get_property("type"))
    entity:emit()
  end

  --If you're tracking an entity, move to follow it and stay on its layer
  sol.timer.start(entity, 300, function()
    if entity.target ~= entity then
      entity:set_position(entity.target:get_position())
      return true
    end
  end)
end


function entity:emit()
  --Create one sprite to use to draw all the particles
  entity.proto_sprite = sol.sprite.create(entity.particle_sprite)
  if entity.particle_animation then entity.proto_sprite:set_animation(entity.particle_animation) end
  entity.particle_sprite_frame_delay = entity.proto_sprite:get_frame_delay()
  entity.particle_sprite_num_frames = entity.proto_sprite:get_num_frames()

  local elapsed_lifespan = 0
  sol.timer.start(entity, 0, function()
    elapsed_lifespan = elapsed_lifespan + entity.frequency
    for i = 1, entity.particles_per_loop do
      entity.particles[#entity.particles + 1] = create_particle()
    end
    if entity.target:exists() and ((entity.duration == nil) or (elapsed_lifespan < entity.duration)) then
      return entity.frequency
    end
  end)

  --Update particles every [timestep]
  sol.timer.start(entity, timestep, function()
    update_particles()
    if #entity.particles > 0 then
      return true
    else
      --No more particles: emitter removes itself
      if entity.remove_after_emitting then
        entity:remove()
      end
    end
  end)
end


function entity:stop()
  entity.duration = 0
end


function entity:set_preset(preset)
  if preset == "burst" then
    entity.particles_per_loop = 50
    entity.frequency = 50
    entity.duration = 10

  elseif preset == "updraft" then
    entity.angle = math.pi / 2
    entity.angle_variance = 0
    entity.particle_speed = 12

  elseif preset == "smoke" then
    entity.particle_speed = 12
    entity.frequency = 30
    entity.particle_lifetime = 2000
    entity.particle_sprite = "effects/smoke_particle"
    entity.particle_scaling = {1, 2.5}
    entity.particle_color = {220, 230, 240}
    entity.particle_opacity = {50,100}
    entity.particle_fade_speed = 5
    entity.shape = "circle"
    entity.width = 6
    entity.angle = math.rad(80)
    entity.angle_variance = math.rad(50)

  elseif preset == "smoke_cloud" then
    entity.particle_speed = 8
    entity.frequency = 120
    entity.particle_lifetime = 3000
    entity.particle_sprite = "effects/smoke_clouds_2"
    entity.particles_per_loop = 1
    entity.particle_opacity = {100,255}
    entity.particle_fade_speed = 5
    entity.particle_animation_loops = false
    entity.particle_color = {190, 200, 210}
    entity.particle_scaling = {1, 1}
    entity.shape = "circle"
    entity.width = 6
    entity.angle = math.rad(80)
    entity.angle_variance = math.rad(20)

  elseif preset == "silver_magic" then
    entity.particle_sprite = "effects/star_particle_small"
    entity.angle = math.pi / 2
    entity.angle_variance = math.rad(10)
    entity.particle_color = {200,220,250}
    entity.particle_opacity = {100,200}

  elseif preset == "fire_burst_small" then
    entity.particles_per_loop = 1
    entity.frequency = 20
    entity.duration = 200
    entity.angle_variance = math.rad(10)
    entity.particle_sprite = "effects/flame"

  elseif preset == "blackflame" then
    entity.particle_sprite = "effects/black_flame"
    entity.particle_animation_loops = false
    entity.particle_opacity = {200,250}
    entity.particles_per_loop = 1
    entity.frequency = 30
    entity.particle_speed = 50
    entity.angle_variance = math.rad(5)

  elseif preset == "sparks" then
    entity.particle_sprite = "effects/spark_particle"
    entity.particles_per_loop = 1
    entity.frequency = 50
    entity.particle_speed = 30
    entity.shape = "circle"
    entity.width = 10
    entity.angle = math.rad(80)
    entity.angle_variance = math.rad(50)

  elseif preset == "charred_magic" then
    entity.particle_speed = 45
    entity.frequency = 30
    entity.particle_sprite = "effects/blood_drop"
    entity.particle_color = {10,10,10}
    entity.particle_opacity = {100,250}
    entity.particle_fade_speed = 10
    entity.shape = "circle"
    entity.width = 4
    entity.angle = math.pi / 2
    entity.angle_variance = math.rad(10)

  elseif preset == "vengeful_spirit" then
    entity.frequency = 30
    entity.particle_lifetime = 2000
    entity.shape = "circle"
    entity.width = 6
    entity.angle = math.pi / 2
    entity.angle_variance = 0
    entity.particle_sprite = "effects/smoke_clouds"
    entity.particle_speed = 35
    entity.particles_per_loop = 1
    entity.particle_opacity = {100,255}
    entity.particle_fade_speed = 5
    entity.particle_animation_loops = false
    entity.particle_color = {255,230, 190}
    entity.particle_scaling = {1, 1}

  elseif preset == "dust" then
    entity.particle_sprite = "effects/smoke_clouds"
    entity.particle_color = {255,240, 210}
    entity.particles_per_loop = 1
    entity.frequency = 100
    entity.particle_speed = 0
    entity.shape = "circle"
    entity.width = 10
    entity.angle = math.pi / 2

  elseif preset == "madness_figment" then
    entity.frequency = 30
    entity.particle_lifetime = 2000
    entity.shape = "circle"
    entity.width = 8
    entity.angle = math.pi / 2
    entity.angle_variance = 0
    entity.particle_sprite = "effects/smoke_clouds"
    entity.particle_speed = 70
    entity.particle_acceleration = -40
    entity.particles_per_loop = 1
    entity.particle_opacity = {180,255}
    entity.particle_fade_speed = 5
    entity.particle_animation_loops = false
    entity.particle_color = {5,0, 0}
    entity.particle_scaling = {1, 1}

  end
end
