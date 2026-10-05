local map_meta = sol.main.get_metatable"map"
local darkness_presets = require"scripts/modules/trillium/fx/lighting/darkness_presets"
local light_source_presets = require"scripts/modules/trillium/fx/lighting/light_source_presets"
local effect_sprites = light_source_presets.get_effect_sprites()

--Config:
local need_lantern_to_light_up = true --set this to false if you don't want to require an item to light the area around the hero
local lantern_item = "gear/lantern"
local lantern_level_savegame_variable = "hero_lantern_level" --this variable determines which sprite to use from the "hero_auras" table of light source presets

local hero_aura_threshold = 450 --how dark it must be before hero aura is applied- sum of RGB values in darkness level
local bleed = 16 --how much beyond the edges of the screen the darkness surface stretches
local default_darkness_level = {255,255,255}

--Create a menu that has surfaces which deal with light and dark colors
local menu = {}
local screen_width, screen_height = sol.video.get_quest_size()
local width, height = screen_width + bleed * 2, screen_height + bleed * 2
menu.dark_color = default_darkness_level
menu.dark = sol.surface.create(width, height)
menu.dark:set_blend_mode"multiply"
menu.dark:fill_color(default_darkness_level)
menu.light = sol.surface.create(width, height)
menu.light:set_blend_mode"add"


function menu:on_draw(dst)
  --TODO: this is pulled directly from the old lighting system. Audit this and see if it could be better
  local game = sol.main.get_game()
  local map = game:get_map()
  local hero = map:get_hero()
  local camera = map:get_camera()
  if not camera then return end
  local cam_x, cam_y = camera:get_position()
  local hx, hy, hz = hero:get_position()
  local bleed_offset_x = cam_x + bleed * 2
  local bleed_offset_y = cam_y + bleed * 2

  --clear the surfaces
  menu.light:clear()
  menu.dark:clear()
  --color surfaces
  menu.dark:fill_color(menu.dark_color)

  --draw different light effects:
  --static light sources
  if map.static_light_sources then
    for _, source in pairs(map.static_light_sources) do
      source.sprite:set_opacity(source.opacity or source.sprite:get_opacity() or 255)
      source.sprite:draw(menu.light, source.x - cam_x + bleed * 2, source.y - cam_y + bleed * 2)
    end
  end
  --dynamic light sources
  if map.dynamic_light_sources then
    for i = #map.dynamic_light_sources, 1, -1 do --iterate backward so we can safely remove sources if they've gone out
      local source = map.dynamic_light_sources[i]
      local exists = source.entity:exists()
      if exists or source.fading_out then --draw sprite if the source exists or is in "fading out" mode
        local x, y, z = source.entity:get_position()
        source.sprite:set_opacity(source.opacity or 255)
        source.sprite:draw(menu.light, x - cam_x + bleed * 2, y - cam_y + bleed * 2)
        source.x, source.y = x, y --set for backup in case the entity is removed, we can still draw the light from it
      elseif source.flagged_for_deletion then --if the source has been flagged to delete (after fading), then remove it
        table.remove(map.dynamic_light_sources, i)
      elseif not exists and not source.fading_out then --if the entity doesn't exist, but hasn't started fading out, unregister and start fade
        map:unregister_light_source(source)
      end
    end
  end

  menu.light:draw(menu.dark, bleed * -1, bleed * -1)
  menu.dark:draw(dst, bleed * -1, bleed * -1)
end



function map_meta:set_darkness_level(darkness_level)
  local map = self
  local game = map:get_game()
  local hero = map:get_hero()
  --Set darkness level:
  menu.dark_color = darkness_presets.get_color_from_preset(darkness_level)
  --Start menu if not already started:
  if sol.menu.is_started(menu) then
    sol.menu.stop(menu)
  end
  sol.menu.start(map, menu)

  --Deal with hero lighting aura:
  --TODO: do this somewhere else??
  local light_sum = menu.dark_color[1] + menu.dark_color[2] + menu.dark_color[3]
  if (light_sum <= hero_aura_threshold) then
    if (need_lantern_to_light_up and game:has_item(lantern_item)) then
      local lantern_variant = game:get_value(lantern_level_savegame_variable) or 0
      if lantern_variant > 0 then
        map:register_light_source(hero, effect_sprites.hero_auras[lantern_variant])
        map.lighting_lantern_active = true
      end
    else
      map.lighting_lantern_active = false
    end
  end
end


function map_meta:get_darkness_level()
  return menu.dark_color
end


function map_meta:get_lantern_aura_active()
  return self.lighting_lantern_active
end



