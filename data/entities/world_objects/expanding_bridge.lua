local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local PANEL_WIDTH = 16 --how much (non-overlapped) distance each panel in the expanding bridge goes for

function entity:on_created()
  entity.max_panels = tonumber(entity:get_property("max_panels") or 10)
  entity.panels = {}
  entity.length = 0

  entity:set_modified_ground("traversable")
  entity:set_property("unstable_floor", "true")
  --Create panels:
  local x, y, z = entity:get_position()
  local direction = entity:get_direction()
  local w, h = entity:get_size()
  local ox, oy = entity:get_origin()
  local sprite_id = entity:get_sprite():get_animation_set()
  for i = 0, entity.max_panels do
    local panel = map:create_custom_entity{
      x = x, y = y, layer = z,
      width = w, height = h, direction = direction,
      sprite = sprite_id,
    }
    panel:set_origin(ox, oy)
    panel:set_modified_ground("traversable")
    panel:set_property("unstable_floor", "true")
    panel:bring_to_back()
    panel.position = 0
    entity.panels[i] = panel
  end

end


--Auto expand to full length:
function entity:expand()
  local direction = entity:get_direction()
  for i, panel in ipairs(entity.panels) do
    local m = sol.movement.create"straight"
    m:set_ignore_obstacles(true)
    m:set_speed(90)
    m:set_angle(direction * math.pi / 2)
    m:set_max_distance(i * PANEL_WIDTH)
    m:start(panel)
    panel.position = i
  end
end


function entity:get_length()
  return entity.length
end


function entity:is_moving()
  local moving = false
  for i, panel in ipairs(entity.panels) do
    if panel.moving then moving = true end
  end
  return moving
end


function entity:set_length(length)
  length = math.min(entity.max_panels, length)
  entity:queue_new_length(length)
end


function entity:queue_new_length(length)
  entity.queued_length = length
  if entity.move_queue_timer then entity.move_queue_timer:stop() end
  entity.move_queue_timer = sol.timer.start(entity, 0, function()
    if entity:is_moving() then
      return 50
    else
      entity:move_to_length(entity.queued_length)
    end
  end)
end



function entity:move_to_length(length)
  local direction = entity:get_direction()
  local current_length = entity.length
  local length_diff = length - current_length

  --move panels:
  local angle = ((direction * math.pi / 2) + (length_diff > 0 and 0 or math.pi))
  --print("Angle is", math.deg(angle))
  for i, panel in ipairs(entity.panels) do
    local current_position = panel.position
    local new_position = math.min(i, length)
    --print("Panel update", current_position, " --> ", new_position)
    local dist = math.abs(new_position - current_position) * PANEL_WIDTH
    --print("Dist:", math.abs(new_position - current_position))
    if dist > 0 then
      local m = sol.movement.create"straight"
      m:set_ignore_obstacles(true)
      m:set_max_distance(dist)
      m:set_angle(angle)
      m:set_speed(90)
      panel.moving = true
      m:start(panel, function()
        panel.moving = nil
      end)
    end
    panel.position = new_position
  end

  entity.length = length
end


