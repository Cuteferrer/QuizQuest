local map_meta = sol.main.get_metatable("map")

function map_meta:draw_entity_bounding_boxes()
  local map = self
  map.enemy_bounding_boxes_active = true
  sol.timer.start(map, 50, function()
    for e in map:get_entities() do
      if not e.bounding_box_surface then
        e.bounding_box_surface = sol.surface.create"px.png"
        e.bounding_box_surface:set_transformation_origin(0,0)
        if e:get_type() == "enemy" then
          e.bounding_box_surface:set_color_modulation{255, 100, 50, 180}
        elseif e:get_type() == "hero" then
          e.bounding_box_surface:set_color_modulation{100, 255, 150, 130}
        elseif e:get_type() == "wall" then
          e.bounding_box_surface:set_color_modulation{255, 50, 50, 220}
        elseif e:get_type() == "sensor" then
          e.bounding_box_surface:set_color_modulation{180, 255, 50, 220}
        else
          e.bounding_box_surface:set_color_modulation{100, 180, 255, 130}
        end
      end
    end
    return true
  end)
end

map_meta:register_event("on_draw", function(self, dst)
  local map = self
  if map.enemy_bounding_boxes_active then
    local camera = map:get_camera()
    local camx, camy = camera:get_position()
    local camw, camh = camera:get_size()
    for e in map:get_entities_in_rectangle(camx, camy, camw, camh) do
      if e:get_type() == "camera" then return
      elseif not e.bounding_box_surface then return end
        local x, y, width, height = e:get_bounding_box()
        e.bounding_box_surface:set_scale(width, height)
        e.bounding_box_surface:draw(dst, x - camx, y - camy)
    end
  end
end)

