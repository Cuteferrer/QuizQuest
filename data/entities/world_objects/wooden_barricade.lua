local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

local bump_damage = 10 --how much damage enemies do when pushing against obstacle, or hero does when rolling


function entity:on_created()
  entity.can_burn = true
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  local x, y, z = entity:get_position()
  entity.cid = "destructible_object_destroyed_" .. map:get_id():gsub("/", "_") .. "_" .. x .."_" .. y .."_" .. z

  --Remove if state is saved and already destroyed:
  if entity:get_property("save_state") and game:get_value(entity.cid) then
    entity:remove()
    return
  end

end


function entity:react_to_heavy_ball(ball)
  entity:destroy()
end


function entity:react_to_fire()
  entity:burn()
end

function entity:react_to_explosion()
  entity:destroy()
end


function entity:react_to_minecart_smash()
  entity:destroy()
end


function entity:destroy()
  if entity.being_destroyed then return end
  entity.being_destroyed = true
  entity:set_traversable_by(true)
  entity:clear_collision_tests()
  local breaking_sound = "breaking_crate"
  sol.audio.play_sound(breaking_sound)

  local sprite = entity:get_sprite()
  local breaking_animation = sprite:has_animation("breaking") and "breaking" or "destroy"
  entity:get_sprite():set_animation(breaking_animation, function()
    entity:set_traversable_by(true)
    entity:remove()
  end)
  --alert nearby enemies
  local ALERT_DISTANCE = 100
  for enemy in map:get_entities_by_type"enemy" do
    if enemy.start_aggro and enemy:get_distance(entity) < ALERT_DISTANCE and enemy:get_layer() == hero:get_layer() and not enemy.aggro then
      enemy:start_aggro()
    end
  end
  --Save state if set
  if entity:get_property("save_state") then game:set_value(entity.cid, true) end

end


function entity:burn()
  if not entity:exists() then return end
  if entity.is_burning then return end

  entity.is_burning = true
  local x, y, z = entity:get_position()
  local w, h = entity:get_size()

  local smolder = entity:create_sprite("elements/smolder", "smolder")
  local em = map:create_particle_emitter(x,y+1,z, "fire")
  em.width, em.height = w, h
  em.frequency = 100
  em:emit()

  local burn_timer = sol.timer.start(entity, 2000, function()
    entity:destroy()
    em:remove()
    map:propagate_fire(x, y, z)
  end)

  function entity:put_out_fire()
    burn_timer:stop()
    entity.is_burning = false
    --entity:remove_sprite(smolder)
    em:remove()
    entity.put_out_fire = nil
  end
end



