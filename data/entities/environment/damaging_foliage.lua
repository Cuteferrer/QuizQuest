local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite
local sound_manager = require("entities/environment/foliage_sound_manager")
entity.can_burn = true

local default_hibernate_duration = 5000


function entity:on_created()
  local damage = entity:get_property("damage") or 3
  local damage_frequency = entity:get_property("damage_frequency") or 500

  sprite = entity:get_sprite()
  if sprite:get_num_frames() > 1 then
    sprite:set_frame(math.random(1, sprite:get_num_frames() - 1))
  end
  entity:set_drawn_in_y_order()
  entity:set_traversable_by(true)

  --regularly emit spore particles:
  sol.timer.start(entity, math.random(1000, 9000), function()
    if map:get_hero():get_distance(entity) > 500 then return 3000 end
    entity:emit_spore_particles(21)
    return math.random(6000, 12000)
  end)


  entity:add_collision_test("overlapping", function(entity, other)
    if other:get_type() == "hero" and not entity.dormant then
      local hero = other
      if not hero.foliage_damage_cooldown then
        sol.audio.play_sound("razorgrass")
        sol.audio.play_sound("hero_hurt")
        hero:blood_splatter(self, 8)
        game:remove_life(damage)
        hero.foliage_damage_cooldown = true
        sol.timer.start(game, damage_frequency, function() hero.foliage_damage_cooldown = false end)
        --Animation:
        if sprite:has_animation("attacking") then
          sprite:set_animation("attacking")
          sol.timer.start(entity, 800, function() sprite:set_animation"stopped" end)
        end
        entity:emit_spore_particles(100)

      end
    end
  end)

end


function entity:emit_spore_particles(amount)
  return --[[
  local em = map:create_particle_emitter(entity:get_position())
  em.duration = amount
  em.frequency = 20
  em.particles_per_loop = 3
  em.particle_color = {220,255,50}
  em.particle_speed = 40 * (amount / 100)
  em.particle_fade_speed = 25
  em.angle = math.pi / 2 - .2
  em.angle_variance = math.pi / 2
  em:emit() --]]
end


function entity:hibernate(duration)
  duration = duration or default_hibernate_duration
  if entity.dormant then return end
  sol.timer.stop_all(entity)
  sol.audio.play_sound("walk_on_grass")
  entity.dormant = true
  sprite:set_animation("retracting")
  sol.timer.start(entity, duration, function()
    sprite:set_animation("emerging", function()
      sprite:set_animation"stopped"
      entity.dormant = false
    end)
  end)
end


function entity:react_to_solforge_weapon()
  entity:hibernate()
end

function entity:react_to_explosion()
  entity:hibernate()
end


function entity:process_hit()
  entity:hibernate()
end


function entity:react_to_fire()
  if not entity:exists() then return end
  local x, y, z = entity:get_position()
  if not entity.is_burning then
    entity.is_burning = true
    local smolder = entity:create_sprite("elements/smolder", "smolder")
    local burn_timer = sol.timer.start(entity, 1000, function()
      entity:remove()
      --map:create_fire{x=x, y=y, layer=z}
      map:propagate_fire(x, y, z)
    end)

    function entity:put_out_fire()
      burn_timer:stop()
      entity.is_burning = false
      entity:remove_sprite(smolder)
      entity.put_out_fire = nil
    end
  end
end


function entity:react_to_wind()
  if entity.put_out_fire then entity:put_out_fire() end
end


function entity:react_to_lightning_bolt()
  sol.timer.start(entity, math.random(100,300), function()
    local x,y,z = entity:get_position()
    map:create_fire{x=x, y=y, layer=z}
  end)
end
