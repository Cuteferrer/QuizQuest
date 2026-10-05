local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()

  entity:set_drawn_in_y_order(true)
  --entity:set_enabled(false)

end


function entity:appear(destruction_callback)
  local hero = map:get_hero()
  local sprite = entity:get_sprite()

  entity.destruction_callback = destruction_callback
  hero:freeze()
  game:start_flash({255,255,255},20)
  sol.timer.start(map, 600, function()
    entity:set_enabled(true)
    local x, y, z = entity:get_position()
    hero:freeze()
    hero:set_position(x, y + 32, z)
    hero:set_direction(1)
    game:stop_flash()
    sol.timer.start(map, 1000, function()
      hero:unfreeze()
    end)
  end)
end



function entity:react_to_solforge_weapon()
  if entity.destroyed then return end
  entity.destroyed = true
  entity:destroy()
end


function entity:destroy()
  local hero = map:get_hero()
  local sprite = entity:get_sprite()
  local x, y, z = entity:get_position()

  hero:freeze()
  hero:set_animation"floating"
  sol.audio.play_sound("spells/fireball_big")
  sol.audio.play_sound("drum_low")
  local em = map:create_particle_emitter(x, y, z, "burst")
  em:emit()
  sprite:set_animation("breaking", function()
    entity:remove()
    game:set_life(game:get_max_life())
    sol.timer.start(map, 1500, function()
      game:set_max_life(game:get_max_life() + 2)
      game:set_life(game:get_max_life())
      sol.audio.play_sound("spells/spell_charge")
      hero:set_animation"stopped"
      local x, y, z = hero:get_position()
      local em = map:create_particle_emitter(x, y, z, "burst")
      em.particles_per_loop = 25
      em.particle_sprite = "effects/star_particle_small"
      em.angle = math.pi / 2
      em.angle_variance = math.rad(15)
      em:emit()
      hero:set_animation"kneeling"

      if entity.destruction_callback then
        entity.destruction_callback()
      else
        hero:unfreeze()
      end
    end)
  end)
end


