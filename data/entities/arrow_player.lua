local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  sprite = entity:create_sprite("entities/arrow")
  entity:set_can_traverse("hero", true)
  entity:set_can_traverse("crystal", true)
  entity:set_can_traverse("crystal_block", true)
  entity:set_can_traverse("destructible", true)
  entity:set_can_traverse("jumper", true)
  entity:set_can_traverse("stairs", false)
  entity:set_can_traverse("stream", true)
  entity:set_can_traverse("switch", true)
  entity:set_can_traverse("teletransporter", true)
  entity:set_can_traverse_ground("deep_water", true)
  entity:set_can_traverse_ground("shallow_water", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("prickles", true)
  entity:set_can_traverse_ground("low_wall", true)

  local direction = entity:get_direction()
  local horizontal = direction % 2 == 0
  if horizontal then
    entity:set_size(16, 8)
    entity:set_origin(8, 6)
  else
    entity:set_size(8, 16)
    entity:set_origin(4, 8)
  end

end

function entity:on_movement_changed(m)
  sprite:set_direction(m:get_direction4())
end


function entity:apply_type(arrow_type)
  entity.arrow_type = arrow_type
end


function entity:fire(dir4)
  local m = sol.movement.create"straight"
  m:set_speed(190)
  m:set_angle(dir4 * math.pi/2)
  m:set_smooth(false)
  m:start(entity)

  function m:on_obstacle_reached()
    sprite:set_animation("reached_obstacle")
    sol.audio.play_sound("arrow_hit")
    entity:stop_movement()
    if entity.arrow_type then entity:create_effect() end
    sol.timer.start(map, 2500, function()
      entity:remove()
    end)
  end

end



function entity:create_effect()
  if entity.arrow_type == "fire" then
    local dir = entity:get_direction()
    local x, y, z = entity:get_position()
    map:create_fire{x=x+game:dx(8)[dir], y=y+game:dy(8)[dir], layer=z}
    entity:get_sprite():set_color_modulation{50,50,50}
    entity:remove()

  elseif entity.arrow_type == "ice" then
    local dir = entity:get_direction()
    local x, y, z = entity:get_position()
    local ice = map:create_ice_blast(x + game:dx(8)[dir], y + game:dy(8)[dir], z)
    ice:set_duration(200)

  elseif entity.arrow_type == "electric" then
    local x, y, z = entity:get_position()
    local dir = entity:get_direction()
    map:create_lightning{x=x+game:dx(8)[dir], y=y+game:dy(8)[dir], layer=z}

  elseif entity.arrow_type == "bomb" then
    local x, y, z = entity:get_position()
    map:create_explosion{x=x, y=y, layer=z}
    sol.audio.play_sound"explosion"
    entity:remove()

  end
end


entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
  local entity_type = other_entity:get_type()

  --Hurt Enemies
  if entity_type == "enemy" then
    entity:process_hitting_enemy(other_entity, other_sprite)

  elseif entity_type == "destructible" and other_entity:get_sprite():get_animation_set() == "destructibles/pot" then
    print"BREAK POT"
    entity:break_pot(other_entity)
  end

end)


entity:add_collision_test("overlapping", function(entity, other_entity)
  local entity_type = other_entity:get_type()

  if entity_type == "crystal" then
    entity:get_movement():on_obstacle_reached()
    sol.audio.play_sound("switch")
    map:change_crystal_state()
    entity:clear_collision_tests()

  elseif entity_type == "switch" and not other_entity:is_walkable() then
    entity:get_movement():on_obstacle_reached()
    local switch = other_entity
    if not switch:is_activated() then
      sol.audio.play_sound("switch")
      switch:set_activated(true)
      switch:on_activated()
    else
      sol.audio.play_sound("switch")
      switch:set_activated(false)
      if switch.on_inactivated then switch:on_inactivated() end
    end
    entity:clear_collision_tests()

  end
end)


--Hit enemies
function entity:process_hitting_enemy(enemy, enemy_sprite)
  if entity.arrow_type then entity:create_effect() end
  if type(enemy:get_attack_consequence("arrow")) == "number" then
    entity:remove()
    enemy:hurt((game:get_value"arrow_damage" or 1) * enemy:get_attack_consequence("arrow"))
  elseif enemy:get_attack_consequence"arrow" == "protected" then
    entity:remove()
    sol.audio.play_sound"sword_tapping"
  end
end


--Break pots
function entity:break_pot(other_entity)
    print"yow pow pow breaking a pot"
--    if other_entity:get_destruction_sound() then sol.audio.play_sound(other_entity:get_destruction_sound()) end
    other_entity:get_sprite():set_animation("destroy", function() entity:remove() other_entity:remove() end)
    local treasure = other_entity:get_treasure()
    if treasure then
      local x,y,z = other_entity:get_position()
      map:create_pickable{
        x=x, y=y, layer=z, treasure_name = treasure,
      }
    end
    entity:clear_collision_tests()
end

