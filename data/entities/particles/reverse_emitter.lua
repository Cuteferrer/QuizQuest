local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local timestep = 10 --how many ms the particles are recalculated


local function create_particle()
  local cx, cy, z = entity.target:get_center_position()
  local gen_radius = entity.radius + math.random( entity.radius_variance * -1, entity.radius_variance)
  local gen_angle = math.rad(math.random(0, 360))
  local x = cx + math.cos(gen_angle) * gen_radius
  local y = cy + math.sin(gen_angle) * gen_radius
  local angle = sol.main.get_angle(x, y, cx, cy)
  local speed = entity.particle_speed + math.random(entity.particle_speed_variance * -1, entity.particle_speed_variance)
  local direction = math.random(0, entity.proto_sprite:get_num_directions() - 1)
  local opacity = math.random(entity.particle_opacity[1], entity.particle_opacity[2])
  local scale = math.random(entity.particle_scaling[1] * 100, entity.particle_scaling[2] * 100) / 100

  return {
    x = x, y = y, layer = z,
    center_x = cx, center_y = cy,
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
    rotation_angle = 0,
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
    if sol.main.get_distance(particle.x, particle.y, particle.center_x, particle.center_y) <= entity.deadzone then
      particle.lifetime = 0
    end
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
    if entity.particle_rotate_to_center then
      particle.rotation_angle = particle.angle
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
  entity.radius = 92
  entity.radius_variance = 8
  entity.deadzone = 12 --radius from center where particles will be removed when they get close enough
  entity.frequency = 10
  entity.particles_per_loop = 1 --can create multiple particles at once if every 10ms isn't fast enough
  entity.duration = 2000 --how long the emitter will last, nil means forever
  entity.particle_sprite = "effects/particle_line"
  entity.particle_animation = nil --Leave nil for the default animation. NOTE: if there are multiple directions to the animation, a random one will be used per particle
  entity.particle_animation_loops = true
  entity.particle_lifetime = 1000
  entity.particle_speed = 30
  entity.particle_speed_variance = 10
  entity.particle_acceleration = 120 --not in any real unit, new_speed = speed + (acceleration / 100) per update
  entity.particle_color = {255, 255, 255}
  entity.particle_opacity = {255, 255} --range from lowest to highest opacity, assigned randomly
  entity.particle_fade_speed = 0 --set to 0 and particles will not fade. Not in a real unit, particles fade by (fade speed / 10) opacity per update
  entity.particle_scaling = {1, 1} --specify min scale, max scale amount, for example {.8, 1.5}
  entity.particle_rotate_to_center = true

  --Draw particles when you draw this entity
  function entity:on_post_draw(camera)
    draw_particles()
  end

  --Automatically set a preset and start emitting
  if entity:get_property("type") then
    entity:set_preset(entity:get_property("type"))
    entity:emit()
  end
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
    if (entity.duration == nil) or (elapsed_lifespan < entity.duration) then
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
      entity:remove()
    end
  end)
end


function entity:set_preset(preset)

end
