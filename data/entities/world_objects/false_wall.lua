local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

local weapon_damage = 1 --how much damage taken when hit

function entity:on_created()
  entity.can_burn = true
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity.hp = tonumber(entity:get_property("hp")) or 3
  local x, y, z = entity:get_position()
  entity.unhidden_savegame_value = map:get_id():gsub("/", "_") .. "_false_wall_" .. x .. "_" .. y .. "_" .. z .. "_state"
  if game:get_value(entity.unhidden_savegame_value) then
    entity:remove()
    return
  end
end


function entity:react_to_solforge_weapon()
  entity:take_damage(weapon_damage)
end

function entity:react_to_hero_projectile()
  entity:take_damage(weapon_damage * 2)
end

function entity:react_to_explosion()
  entity:destroy()
end


function entity:take_damage(amount)
  if entity.being_damaged then return end
  entity.being_damaged = true
  sol.timer.start(entity, 100, function() entity.being_damaged = false end)
  sol.audio.play_sound("impact_wood")
  entity.hp = entity.hp - amount
  if entity.hp <= 0 then
    entity:destroy()
  end
  entity:shake(hero:get_angle(entity))
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
    else
      sprite:set_xy(0,0)
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
  entity:clear_collision_tests()
  if not game.breakable_object_sound_playing then
    sol.audio.play_sound("breaking_crate")
    game.breakable_object_sound_playing = true
    sol.timer.start(game, 50, function()
      game.breakable_object_sound_playing = nil
    end)
  end
  entity:get_sprite():set_animation("breaking", function()
    entity:set_traversable_by(true)
    entity:remove()
  end)
  --Save state
  game:set_value(entity.unhidden_savegame_value, true)
  --Hide linked occluders
  local occluder = map:get_entity(entity:get_property"linked_occluder" or "")
  if occluder then occluder:hide() end

  --[[alert nearby enemies
  local ALERT_DISTANCE = 100
  for enemy in map:get_entities_by_type"enemy" do
    if enemy.start_aggro and enemy:get_distance(entity) < ALERT_DISTANCE and enemy:get_layer() == hero:get_layer() and not enemy.aggro then
      enemy:start_aggro()
    end
  end
  --]]
end


