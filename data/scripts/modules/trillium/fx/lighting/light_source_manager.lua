--[[
Created by Max Mraz, licensed MIT

--]]

local manager = {}
local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"
local light_source_presets = require"scripts/modules/trillium/fx/lighting/light_source_presets"

local effect_sprites = light_source_presets.get_effect_sprites()


--Add static light source:
-- Static sources look like: { sprite = spriteUserdata, x = 10, y = 100, opacity = 255 }
-- It's unlikely you'll ever add a static light source, since that kinda means it isn't static. But I'll still make it possible.
function map_meta:add_static_light_source(entity, sprite)
  assert(entity, "Must pass an entity to map:add_static_light_source(entity, sprite)")
  assert(sprite, "Must pass a sprite to map:add_static_light_source(entity, sprite)")
  local map = self
  if not map.static_light_sources then map.static_light_sources = {} end
  if map.static_light_sources[entity] then return end
  local x, y, z = entity:get_position()
  sprite = light_source_presets.get_sprite_or_preset(sprite)
  map.static_light_sources[entity] = { x = x, y = y, sprite = sprite, opacity = 255 }
end


--Add dynamic light source:
-- Dynamic sources look like: { entity = entityUserdata, sprite = spriteUserdata }
function map_meta:add_dynamic_light_source(entity, sprite)
  assert(entity, "Must pass an entity to map:add_dynamic_light_source(entity, sprite)")
  assert(sprite, "Must pass a sprite to map:add_dynamic_light_source(entity, sprite)")
  local map = self
  if not map.dynamic_light_sources then map.dynamic_light_sources = {} end
  sprite = light_source_presets.get_sprite_or_preset(sprite)
  local source = { entity = entity, sprite = sprite, opacity = 255 } --TODO: start with 0 opacity and fade in
  source.opacity = 255
  --fade_in_light_source(source, speed) --TODO??
  table.insert(map.dynamic_light_sources, source)
  return source
end

--Little wrapper, because 'map:add_light_source()' is easier to remember than 'add_dynamic_light_source()'
function map_meta:register_light_source(entity, sprite)
  sol.timer.start(self,10,function()
    source = self:add_dynamic_light_source(entity, sprite)
  end)

end


function map_meta:unregister_light_source(source)
  local map = self
  source.fading_out = true
  sol.timer.start(map, 10, function()
    source.opacity = math.max(0, source.opacity - 20)
    if source.opacity <= 0 then
      source.opacity = 0
      source.fading_out = false
      source.flagged_for_deletion = true
    else
      return true
    end
  end)
end


function map_meta:scan_for_static_light_sources()
  local map = self
  for entity in map:get_entities() do
    local name = entity:get_name()
    if not name then name = "" end

    if map.static_light_sources[entity] then
      --nothing, already added
    elseif name:match("^sprite_light_source") then
      add_static_light_source(entity)

    elseif name:match("%^lighting_effect") then
      local x, y, z = entity:get_position()
      local source = {x=x, y=y}
      if string.match(name, "torch") then
        source.sprite = effect_sprites.torch
      elseif string.match(name, "candle") then
        source.sprite = effect_sprites.candle
      end
      table.insert(map.static_light_sources, source)

    elseif entity:get_property("lighting_effect_type") or entity.lighting_effect_type then
      local effect_type = entity:get_property"lighting_effect_type" or entity.lighting_effect_type
      --If entity sprite light source
      if effect_type == "sprite" then
        map:add_static_light_source(entity, entity:get_sprite())
      --If preset light source
      else
        local x, y, z = entity:get_position()
        local source = {x=x, y=y, opacity = 255}
        if effect_type == "torch" then
          source.sprite = effect_sprites.torch
        elseif effect_type == "candle" then
          source.sprite = effect_sprites.candle
        end
        table.insert(map.static_light_sources, source)
      end
    end
  end
end


map_meta:register_event("on_started", function(map)
  map.static_light_sources = {}
  map.dynamic_light_sources = {}

  --Do some checking for light sources:
  map:scan_for_static_light_sources()
end)


return manager
