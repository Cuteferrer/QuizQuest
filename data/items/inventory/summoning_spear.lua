local item = ...
local game = item:get_game()

item:register_event("on_started", function(self)
  self:set_savegame_variable("possession_summoning_spear")
  self:set_assignable(true)
  item:set_ammo("_magic")
end)


item:register_event("on_using", function(self)
  local map = item:get_map()
  if item:get_map():has_entity("hero_thrown_summoning_spear")
  and not map:get_entity("hero_thrown_summoning_spear").returning
  and item:try_spend_ammo(20) then
    item:summon_spear(350)
  elseif not item:get_map():has_entity("hero_thrown_summoning_spear") then
    item:throw_spear(350, 200) --speed, distance
  else
    item:set_finished()
  end
end)


function item:summon_spear(speed)
  local map = item:get_map()
  local spear = map:get_entity("hero_thrown_summoning_spear")
  if spear.returning then return end
  spear.returning = true
  spear:get_sprite():set_animation("returning")
  spear:add_collision_test("sprite", function(spear, other_entity)
    if other_entity:get_type() == "enemy" then
      item:smack_enemy(other_entity)
    end
  end)
  local m = sol.movement.create("target")
  m:set_ignore_obstacles(true)
  m:set_speed(speed or 250)
  m:start(spear, function()
    sol.audio.play_sound"arrow_hit"
    spear:remove()
  end)
  sol.timer.start(item, 100, function()
    if spear:exists() then
      sol.audio.play_sound"boomerang"
      return true
    end
  end)
  item:set_finished()
end


function item:throw_spear(speed, distance)
  local hero = game:get_hero()
  local map = item:get_map()
  hero:freeze()
  hero:get_sprite():set_animation("throwing", function() hero:unfreeze() end)
  sol.audio.play_sound"sword4"
  local x,y,z = hero:get_position()
  local direction = hero:get_direction()
  local spear = map:create_custom_entity({
    direction = direction, x = x, y = y, layer = z, width = 8, height = 8,
    sprite = "entities/summoning_spear", name = "hero_thrown_summoning_spear"
  })
  spear:set_can_traverse_ground("deep_water", true)
  spear:set_can_traverse_ground("shallow_water", true)
  spear:set_can_traverse_ground("hole", true)
  spear:set_can_traverse_ground("lava", true)
  spear:set_can_traverse_ground("low_wall", true)
  spear:set_can_traverse("hero", true)
  spear:set_can_traverse("switch", true)
  spear:set_can_traverse("teletransporter", true)
  spear:set_can_traverse("jumper", true)
  spear:set_drawn_in_y_order(true)
  --manage hitting stuff
  spear:add_collision_test("sprite", function(spear, other_entity)
    if other_entity:get_type() == "enemy" then
      item:smack_enemy(other_entity)
    end
  end)

  --throw
  local m = sol.movement.create("straight")
  m:set_max_distance(distance or 200)
  m:set_speed(speed or 200)
  m:set_ignore_obstacles(false)
  m:set_smooth(false)
  m:set_angle(direction * math.pi / 2)
  m:start(spear, function()
    item:land(spear)
  end)
  function m:on_obstacle_reached()
    item:land(spear)
  end
end


function item:land(spear)
  spear:stop_movement()
  spear:get_sprite():set_animation("ground")
  spear:clear_collision_tests()
  if spear:get_ground_below() == "deep_water" then
    spear:get_sprite():set_animation"splash"
    sol.audio.play_sound"splash"
  else
    sol.audio.play_sound"arrow_hit"
  end
end


--smack enemy
function item:smack_enemy(enemy)
  local reaction = enemy:get_attack_consequence("boomerang")
  if reaction ~= "protected" and reaction ~= "ignored" then
    enemy:hurt(game:get_value("summoning_spear_damage") or 1)
  end
end
