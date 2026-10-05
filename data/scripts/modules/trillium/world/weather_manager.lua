--[[
By Max Mraz, licensed MIT

Creates weather effects. Depends on particle emitters, so make sure you've imported those.
Usage:
map:start_weather(weather_type)
weather types:
- rain
- sprinkle
- snow
- leaves
--]]

local manager

local map_meta = sol.main.get_metatable"map"


local function get_weather_emitter(camera)
  local map = camera:get_map()
  local em = map:create_particle_emitter(camera:get_position())
  local w, h = sol.video.get_quest_size()
  --em.target = camera
  em.width, em.height = w * 2, h * 2
  em.angle = 3 * math.pi / 2
  em.angle_variance = 0
  em.particles_per_loop = 3

  sol.timer.start(map, 200, function()
    local x, y, z = camera:get_position()
    em:set_position(x + w/2, y + h, z)
    return true
  end)

  return em
end


function map_meta:start_weather(weather_type)
  assert(type(weather_type) == "string", "Must pass a valid weather type when calling 'map:start_weather(weather_type)'")
  local map = self
  if not map.weather_emitters then map.weather_emitters = {} end
  for camera in map:get_entities_by_type("camera") do
    local em = get_weather_emitter(camera)

    if weather_type == "rain" then
      em.particle_sprite = "weather/rain"
      em.particle_speed = 300
      em.particle_opacity = {200,255}

      local splash_em = get_weather_emitter(camera)
      splash_em.particle_speed = 0
      splash_em.particle_speed_variance = 0
      splash_em.particle_sprite = "weather/rain"
      splash_em.particle_animation = "drop_splash"
      splash_em.particles_per_loop = 1
      splash_em:emit()
      splash_em.type = "rain"
      table.insert(map.weather_emitters, splash_em)

      map:set_darkness_level{200,240,255}

    elseif weather_type == "sprinkle" then
      em.particle_sprite = "weather/rain"
      em.particle_speed = 300
      em.particle_opacity = {200,255}
      em.particles_per_loop = 1
      em.frequency = 100

      local splash_em = get_weather_emitter(camera)
      splash_em.particle_speed = 0
      splash_em.particle_speed_variance = 0
      splash_em.particle_sprite = "weather/rain"
      splash_em.particle_animation = "drop_splash"
      splash_em.particles_per_loop = 1
      splash_em.frequency = 300
      splash_em:emit()
      splash_em.type = "rain"
      table.insert(map.weather_emitters, splash_em)

      --map:set_darkness_level{200,240,255}

    elseif weather_type == "snow" then
      em.particle_sprite = "weather/snow"
      em.particle_speed = 100
      em.angle = 3 * math.pi / 2 + math.rad(20)
      em.angle_variance = math.rad(5)
      em.particle_rotation = "random"
      em.particle_rotation_speed = {math.rad(1), math.rad(3)}

    elseif weather_type == "leaves" then
      em.particle_sprite = "weather/leaf_2"
      em.particle_speed = 70
      em.angle = 3 * math.pi / 2 + math.rad(20)
      em.angle_variance = math.rad(10)
      em.particles_per_loop = 1
      em.frequency = 400
      em.particle_generation_offset = {0, -200}
      em.particle_lifetime = 5000
      em.particle_fade_speed = 5
      
    end

    em:emit()
    em.type = weather_type
    table.insert(map.weather_emitters, em)
  end
end


return manager

