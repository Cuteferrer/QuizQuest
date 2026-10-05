local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("lava", true)
  --entity:set_drawn_in_y_order(true)
  --Don't activate collision for a frame to allow code to create these where they aren't damaging until a certain animation or something
  sol.timer.start(entity, 10, function()
    if not entity.delay_collision then
      entity:activate_collision()
    end
  end)
end


function entity:activate_collision()
  entity.damage = entity.damage or 1
  entity.damage_type = entity.damage_type or "physical"
  entity.damage_frequency = entity.damage_frequency or nil --if defined, can hit entities multiple times
  entity.must_overlap = entity.must_overlap or false
  entity.hit_callback = entity.hit_callback or nil --can define a callback for when attack hits. Takes hero it hit as an argument.

  local collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other)
    if collided_entities[other] then return end
    collided_entities[other] = true
    if entity.damage_frequency then
      sol.timer.start(entity, entity.damage_frequency, function() collided_entities[other] = nil end)
    end
    local other_type = other:get_type()

    --Little determination if the attack can hit the target, based on who created it:
    local can_hit = false
    if not entity.parent_enemy then
      can_hit = (other_type == "hero")
    elseif entity.parent_enemy.can_target then
      can_hit = entity.parent_enemy:can_target(other)
    end

    if (other_type == "hero" or other_type == "enemy") and can_hit and not entity.harmless then
      if entity.must_overlap and not entity:overlaps(other) then return end
      if other.process_hit then
        other:process_hit({damage = entity.damage, enemy = entity, damage_type = entity.damage_type})
      elseif other_type == "hero" then
        other:start_hurt(enemy, damage)
      end
      --Allow a custom callback when hitting the hero:
      if entity.hit_callback then entity.hit_callback(other) end
    end
  end)
end


function entity:remove_after_animation()
  local sprite = entity:get_sprite()
  function sprite:on_animation_finished()
    entity:remove()
  end
end

