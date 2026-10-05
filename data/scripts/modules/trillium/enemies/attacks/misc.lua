local manager = {}

function manager.apply_behavior(enemy)
  local map = enemy:get_map()

  --Magic Sigil:
  function enemy:magic_sigil(sprite_id, animation, offset)
    sprite_id = sprite_id or "items/spell_sigil_eye"
    animation = animation or "sigil"
    local sprite_y_offset = offset or -56
    local x, y, z = enemy:get_position()
    local spell_sigil = map:create_custom_entity{
      x=x, y=y, layer=z, width=16,height=16,direction=0,
      model = "ephemeral_effect", sprite = sprite_id,
    }
    local spell_sprite = spell_sigil:get_sprite()
    spell_sprite:set_animation(animation)
    spell_sprite:set_xy(0, sprite_y_offset)
    return spell_sigil
  end

end


return manager
