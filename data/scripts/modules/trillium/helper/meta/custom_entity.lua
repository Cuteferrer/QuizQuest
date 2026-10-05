local entity_meta = sol.main.get_metatable"custom_entity"


entity_meta:register_event("on_created", function(entity)
  if entity:get_property("drawn_in_y_order") then
    entity:set_drawn_in_y_order(true)
  end

  if entity:get_property("is_blocking") then
    entity:set_traversable_by(false)
  end

  if entity:get_property("opacity") then
    local opacity = entity:get_property"opacity"
    entity:get_sprite():set_opacity(opacity)
  end

  if entity:get_property("pulse_opacity") then
    local max = tonumber(entity:get_property("max_opacity")) or 255
    local min = tonumber(entity:get_property("min_opacity")) or 0
    local freq = tonumber(entity:get_property("pulse_frequency")) or nil
    entity:pulse_opacity{
      min = min, max = max,
      pulse_frequency = freq,
    }
  end

  if entity:get_property("blood_spatter") then
    if not entity:get_game():get_value("option_show_blood") then entity:remove() end
  end

  if entity:get_property("visible") == "false" or (entity:get_property("visible") == false) then
    entity:set_visible(false)
  end


  if entity:get_property("dialog") then
    function entity:on_interaction()
      entity:get_game():start_dialog(entity:get_property("dialog"))
    end
  end

end)


function entity_meta:is_on_screen()
  local entity = self
  local map = entity:get_map()
  local camera = map:get_camera()
  local camx, camy = camera:get_position()
  local camwi, camhi = camera:get_size()
  local entityx, entityy = entity:get_position()

  local on_screen = entityx >= camx and entityx <= (camx + camwi) and entityy >= camy and entityy <= (camy + camhi)
  return on_screen
end


function entity_meta:pulse_opacity(props)
  local pulse_frequency = props.pulse_frequency or 40
  local max = props.max or 255
  local min = props.min or 0
  local starting_opacity = props.starting_opacity
  local step = props.step_size or 2
  local step_direction = props.step_direction or 1
  local entity = self
  local sprite = self:get_sprite()
  if starting_opacity then sprite:set_opacity(starting_opacity) end
  sol.timer.start(entity, 0, function()
    local opacity = sprite:get_opacity()
    local new_opacity = opacity + (step * step_direction)
    --turn around if we've reached maximum or minimum
    if new_opacity >= max then
      step_direction = -1
      new_opacity = max
    elseif new_opacity <= min then
      step_direction = 1
      new_opacity = min
    end
    sprite:set_opacity(new_opacity)
    return pulse_frequency
  end)
end


--Returns an array of nearby enemies, sorted by distance to the hero (closest first) -- can be limited to X number of enemies with a second argument
function entity_meta:select_nearby_enemies(range, limit)
  local entity = self
  local map = self:get_map()
  local x, y, z = self:get_position()
  local enemies = {}
  local enemies_captured = 0

  for ent in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
    local distance = ent:get_distance(self)
    if (ent:get_type() == "enemy") and (distance <= range) then
      enemies_captured = enemies_captured + 1
      ent.snedist = distance
      enemies[enemies_captured] = ent
    end
  end
  --Sort table by distance
  table.sort(enemies, function(a, b)
    return a.snedist < b.snedist
  end)
  --Truncate:
  local limited_enemies = {}
  for i = 1, limit do
    limited_enemies[i] = enemies[i]
  end

  return limited_enemies
end
