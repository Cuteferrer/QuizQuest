local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_modified_ground("traversable")
  entity:set_property("unstable_floor", "true")
  entity.triggering_types = { hero = true }
  entity.trigger_sound = entity:get_property("trigger_sound") or "impact_wood_2"
  entity.collapse_delay = entity:get_property("collapse_delay") or 1000
  entity.collapse_sound = entity:get_property("collspse_sound") or "ground_burst"
  entity.reform_delay = entity:get_property("reform_delay") or nil
  entity.reform_sound = entity:get_property("reform_sound") or "running"

  --Allow enemies to also cause floor to collapse:
  if entity:get_property("triggered_by_enemies") then
    entity.triggering_types.enemy  =true
  end

  entity:add_collision_test("origin", function(entity, other)
    if entity.collapse_triggered then return end
    if entity.triggering_types[other:get_type()] then
      entity:start_collapsing()
    end
  end)
end


function entity:start_collapsing()
  entity.collapse_triggered = true
  entity:make_sound(entity.trigger_sound)
  --shaking:
  entity:shake()
  sol.timer.start(entity, entity.collapse_delay, function()
    entity:collapse()
  end)
  --dust effect:
  entity:dust_cloud()
end


function entity:shake()
  local sprite = entity:get_sprite()
  local count = 0
  local elapsed_time = 0
  local frequency = 20
  sol.timer.start(entity, frequency, function()
    count = count + 1
    local dx = math.cos(count) * 1.3
    sprite:set_xy( dx , 0)
    elapsed_time = elapsed_time + frequency
    if elapsed_time < entity.collapse_delay then
      return true
    else
      sprite:set_xy(0,0)
    end
  end)
end


function entity:dust_cloud()
  local x, y, z = entity:get_center_position()
  local w, h = entity:get_size()
  local em = map:create_particle_emitter(x, y, z, "burst")
  em.particle_sprite = "effects/particle_dust"
  em.particle_animation_loops = false
  em.particle_speed = 60
  em.particles_per_loop = 5
  em.particle_opacity = {30,70}
  em.width = w
  --em.angle_variance = 0
  em:emit()
end


function entity:collapse()
  entity:set_modified_ground("empty")
  entity:make_sound(entity.collapse_sound)

  local sprite = entity:get_sprite()
  if sprite:has_animation("collapsing") then
    sprite:set_animation("collapsing", function()
      entity:set_visible(false)
    end)
  else
    entity:set_visible(false)
  end

  if entity.reform_delay then
    sol.timer.start(entity, entity.reform_delay, function()
      entity:reform()
    end)
  else
    entity:remove()
  end
end


function entity:reform()
  local sprite = entity:get_sprite()
  if sprite:has_animation("reforming") then
    sprite:set_animation("reforming", function()
      sprite:set_animation("stopped")
    end)
  else
    sprite:set_animation("stopped")
  end
  entity:make_sound(entity.reform_sound)
  entity:set_modified_ground("traversable")
  entity:set_visible(true)
  entity.collapse_triggered = false
  entity:dust_cloud()
end


