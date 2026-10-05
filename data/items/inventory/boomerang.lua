local item = ...
local game = item:get_game()

item:register_event("on_started", function(self)
  self:set_savegame_variable("possession_boomerang")
  self:set_assignable(true)
end)


item:register_event("on_using", function(self)
  local hero = self:get_map():get_entity("hero")
  local can_throw = not item:get_map():has_entity("hero_thrown_boomerang")
  if self:get_variant() == 1 and can_throw then
    self:do_boomerang(96, 170, "boomerang1", "entities/boomerang1")
  elseif can_throw then
    -- boomerang 2: longer and faster movement
    self:do_boomerang(170, 250, "boomerang1", "entities/boomerang1")
  end
  self:set_finished()
end)


function item:do_boomerang(distance, speed, hero_animation, boom_sprite)
  local hero = game:get_hero()
  local map = item:get_map()
  speed = speed or 170
  distance = distance or 75
  hero:freeze()
  hero:get_sprite():set_animation(hero_animation, function() hero:unfreeze() end)
  local x,y,l = hero:get_position()

  --make boomerang
  local boomerang = map:create_custom_entity({
    direction = 0, x = x, y = y, layer = l, width = 16, height = 16,
    sprite = boom_sprite, name = "hero_thrown_boomerang"
  })
  boomerang:set_can_traverse_ground("deep_water", true)
  boomerang:set_can_traverse_ground("shallow_water", true)
  boomerang:set_can_traverse_ground("hole", true)
  boomerang:set_can_traverse_ground("lava", true)
  boomerang:set_can_traverse_ground("low_wall", true)
  boomerang:set_can_traverse("hero", true)
  boomerang:set_can_traverse("pickable", true)
  boomerang:set_can_traverse("switch", true)
  boomerang:set_can_traverse("teletransporter", true)
  boomerang:set_can_traverse("enemy", true)

  --manage hitting stuff
  boomerang:add_collision_test("touching", function(boom, other)
    if other:get_type() == "enemy" then
      item:smack_enemy(other)
    elseif other:get_type() == "switch" and not other:is_walkable() then
      other:toggle()
      item:come_back(boomerang, speed)
    elseif (other:get_type() == "pickable") or (other.boomerang_catchable) then
      boomerang:clear_collision_tests()
      item:catch_entity(boomerang, other)
      item:come_back(boomerang, speed)
    end
  end)

  --throw
  local m = sol.movement.create("straight")
  m:set_max_distance(distance)
  m:set_speed(speed)
  m:set_ignore_obstacles(false)
  local angle_options = {[0]=0,[1]=math.pi/2,[2]=math.pi,[3]=3*math.pi/2}
  m:set_angle(angle_options[hero:get_sprite():get_direction()])
  m:start(boomerang, function() item:come_back(boomerang, speed) end)
  function m:on_obstacle_reached()
    item:come_back(boomerang, speed)
  end
  sol.timer.start(map, 160, function()
    if map:has_entities("hero_thrown_boomerang") then
      sol.audio.play_sound("boomerang")
      return true
    end
  end)
end


function item:come_back(boomerang, speed)
  boomerang:stop_movement()
  speed = speed or 170
  local m = sol.movement.create("target")
  m:set_ignore_obstacles(true)
  m:set_speed(speed+20)
  m:start(boomerang, function()
    boomerang:remove()
  end)
end


function item:smack_enemy(enemy)
  local reaction = enemy:get_attack_consequence("boomerang")
  if reaction ~= "protected" and reaction ~= "ignored" then
    if not enemy.immobilize_immunity then
      enemy:immobilize()
    end
    local damage = {1, 5}
    damage = damage[item:get_variant()]
    enemy:hurt(damage)
  end
end


function item:catch_entity(boomerang, entity)
  function boomerang:on_position_changed(x, y, z)
    entity:set_position(x, y, z)
  end
end
