local manager = {}


--Preset effect sprites:
local effect_sprites = {
  torch = sol.sprite.create"entities/effects/light_l",
  candle = sol.sprite.create"entities/effects/light_s",
  explosion = sol.sprite.create"entities/effects/light_xl",
  hero_auras = { --each corresponds with a variant of the lantern_item, if need_lantern_to_light_up is true
    sol.sprite.create"entities/effects/light_m",
    sol.sprite.create"entities/effects/light_l",
    sol.sprite.create"entities/effects/light_xl",
    sol.sprite.create"entities/effects/light_xxl",
    sol.sprite.create"entities/effects/light_xxxl",
  },
  lantern = sol.sprite.create"entities/effects/light_l",
  light_s = sol.sprite.create"entities/effects/light_s",
  light_m = sol.sprite.create"entities/effects/light_m",
  light_l = sol.sprite.create"entities/effects/light_l",
  light_xl = sol.sprite.create"entities/effects/light_xl",
}
--add color to effects
effect_sprites.torch:set_color_modulation{255, 230, 150}
effect_sprites.candle:set_color_modulation{255, 230, 130}
for k, sprite in pairs(effect_sprites.hero_auras) do
  sprite:set_color_modulation{215, 190, 140}
end
effect_sprites.lantern:set_color_modulation{230, 210, 240}
effect_sprites.explosion:set_color_modulation{255, 240, 180}

--set blend modes
for i=1, #effect_sprites do
  effect_sprites[i]:set_blend_mode"blend"
end


function manager.get_effect_sprites()
  return effect_sprites
end


function manager.get_sprite_or_preset(preset)
  if effect_sprites[preset] then
    return effect_sprites[preset]
  elseif sol.main.get_type(preset) == "sprite" then
    return preset
  else
    return sol.sprite.create(preset)
  end
end


return manager
