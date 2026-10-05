local map_meta = sol.main.get_metatable"map"

--local w, h = sol.video.get_quest_size()
--local particle_surface = sol.surface.create(w, h)

--[[
map_meta:register_event("on_started", function(map)
  --if not map.particle_surfaces then map.particle_surfaces = {} end
  --map.particle_surface = particle_surface
  map.particle_emitters = map.particle_emitters or {}
end)

map_meta:register_event("on_draw", function(map, dst_surface)
  local i = 0
  --for _, _ in pairs(map.particle_emitters) do i = i + 1 end
  --if i > 0 then print("num tables:", i) end
  for _, emitter in pairs(map.particle_emitters) do
    if emitter.particle_surface then
      emitter:update_particle_surface()
      emitter.particle_surface:draw(dst_surface)
    end
  end
end)
--]]


function map_meta:create_particle_emitter(x, y, z, preset)
  local em_type = (preset == "reverse") and "reverse_emitter" or "emitter"
  local emitter = self:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0, model="particles/" ..em_type,
  }
  if preset then
    emitter:set_preset(preset)
  end
  return emitter
end

