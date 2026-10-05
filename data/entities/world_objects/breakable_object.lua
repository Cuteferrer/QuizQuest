local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

local bump_damage = 10 --how much damage enemies do when pushing against obstacle, or hero does when rolling
local sound_overlap_buffer_duration = 100 --how long to ignore sound effects to prevent multiple SFX overlapping and being super loud


function entity:on_created()
  entity.can_burn = true
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity.hp = tonumber(entity:get_property("hp")) or 1
  local x, y, z = entity:get_position()
  entity.cid = "destructible_object_destroyed_" .. map:get_id():gsub("/", "_") .. "_" .. x .."_" .. y .."_" .. z

  --Remove if state is saved and already destroyed:
  if entity:get_property("save_state") and game:get_value(entity.cid) then
    entity:remove()
    return
  end

  --If requires explosion to destroy, don't add collision_tests:
  if entity:get_property("explosion_required") then
    entity.explosion_required = true
    return
  end

  --Touching test
  local function process_collision(entity, other_entity)
    if other_entity:get_type() == "enemy" and other_entity.aggro and not entity.ignore_enemies then
      entity:take_damage(bump_damage)
    end

    if other_entity:get_type() == "hero" then
      local state, state_ob = other_entity:get_state()
      if state == "custom" and state_ob:get_description() == "dashing" then
        entity:take_damage(bump_damage)
      end
    end
  end

  entity:add_collision_test("touching", function(entity, other_entity)
    process_collision(entity, other_entity)
  end)

  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    process_collision(entity, other_entity)
    if other_sprite:get_animation_set() == hero:get_sword_sprite_id() then
      entity:take_damage(bump_damage)
    end
  end)

end


function entity:react_to_solforge_weapon()
  entity:take_damage(bump_damage)
end


function entity:react_to_fire()
  entity:maybe_explode()
end

function entity:react_to_explosion()
  local exploded = entity:maybe_explode()
  if not exploded then
    entity:destroy() --this will destroy it even if "explosion_required" property is true
  end
end


function entity:react_to_bullet(bullet)
  local exploded = entity:maybe_explode()
  if exploded then
    bullet:remove() --remove a bullet if it causes an explosion
  else
    entity:take_damage(bullet.damage * 1.5)
  end
end


--Explode if explosive:
function entity:maybe_explode()
  if entity:get_property("explosive") then
    entity:set_property("explosive", nil) --prevent infinite loop
    entity:clear_collision_tests()
    local x, y, z = entity:get_position()
    map:create_explosion{ x=x, y=y, layer=z }
    entity:destroy()
    return true
  else
    return false
  end
end


function entity:take_damage(amount)
  --Ignore damage if needs explosion:
  if entity.explosion_required then
    sol.audio.play_sound"sword_tapping"
    return
  end
  entity.hp = entity.hp - amount
  local hit_sound = entity:get_property("sound") or "impact_wood"
  if not game.breakable_object_hit_sound_playing then
    game.breakable_object_hit_sound_playing = true
    sol.timer.start(game, sound_overlap_buffer_duration, function() game.breakable_object_hit_sound_playing = nil end)
    entity:make_sound(hit_sound)
  end
  if entity.hp <= 0 then
    entity:destroy()
  end
  entity:shake(hero:get_angle(entity))
  entity:bounce_animation()
end


function entity:shake(angle)
  local amplitude = 1
  local num_shakes = 6
  local shake_freq = 30
  local sprite = entity:get_sprite()
  angle = sol.main.get_direction4(angle) * math.pi / 2
  local dx = math.cos(angle) * amplitude
  local dy = math.sin(angle) * amplitude

  local shake_count = 1
  function shake()
    local alter = shake_count % 2 == 0 and 1 or -1
    sprite:set_xy(dx * alter, dy * alter)
    shake_count = shake_count + 1
    if shake_count <= num_shakes then
      sol.timer.start(entity, shake_freq, function()
        shake()
      end)
    end
  end
  shake()
end

function entity:bounce_animation()
  local sprite = entity:get_sprite()
  --sprite:set_blend_mode("add")
  sprite:set_scale(1.1, 1.1)
  sol.timer.start(entity, 60, function()
    --sprite:set_blend_mode("blend")
    sprite:set_scale(1, 1)
  end)
end




function entity:destroy()
  entity.destroy = function() end --prevent from being called multiple times
  entity:set_traversable_by(true)
  entity:clear_collision_tests()
  if not game.breakable_object_sound_playing then
    local breaking_sound = entity:get_breaking_sound_from_sprite() or "breaking_crate"
    entity:make_sound(breaking_sound)
    game.breakable_object_sound_playing = true
    sol.timer.start(game, sound_overlap_buffer_duration, function()
      game.breakable_object_sound_playing = nil
    end)
  end
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


function entity:get_breaking_sound_from_sprite()
  local id = entity:get_sprite():get_animation_set()
  local sound = nil
  if id:match("vase") or id:match("pot") then
    sound = "breaking_vase"
  elseif id:match("crate") or id:match("barrel") then
    sound = "breaking_crate"
  end
  return sound
end


