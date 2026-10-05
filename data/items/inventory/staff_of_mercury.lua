local item = ...
local game = item:get_game()

item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_staff_of_mercury")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  local map = item:get_map()
  local hero = map:get_hero()
  local sparks = item.sparks or {}
  local num_sparks = 16
  local radius = 24
  local x, y, z = hero:get_position()

  if not item.sparks_enabled then
    if not item:try_spend_ammo(10) then
      item:set_finished()
      return
    end
    item.sparks_enabled = true
    for i=1, num_sparks do
      sparks[i] = map:create_custom_entity{
        x=x, y=y, layer=z, width=8, height=8, direction=0, sprite="elements/lightning_ball_small",
      }
      sparks[i]:add_collision_test("sprite", function(spark, enemy)
        if enemy:get_type() == "enemy" then
          enemy:hurt(1)
        end
      end)
      sparks[i]:set_can_traverse_ground("deep_water", true)
      sparks[i]:set_can_traverse_ground("hole", true)
      sparks[i]:set_can_traverse_ground("low_wall", true)
      local m = sol.movement.create"circle"
      m:set_center(hero)
      m:set_radius(radius)
      m:set_angle_from_center( 2 * math.pi / num_sparks * i )
      m:set_angular_speed(5)
      m:set_ignore_obstacles(true)
      m:start(sparks[i])
    end

    --Drain magic while using
    sol.timer.start(item, 50, function()
      if item.sparks_enabled and item:try_spend_ammo(1) then
        return true
      else
        item.sparks_enabled = false
        for i=1, num_sparks do
          sparks[i]:remove()
        end
        sparks = {}      
      end
    end)

  else --sparks already protecting
    item.sparks_enabled = false
    for i=1, num_sparks do
      sparks[i]:remove()
    end
    sparks = {}
  end

  item.sparks = sparks --save sparks so next swing can remove them

  hero:set_animation("rod_swing", function()
    hero:set_animation"stopped"
    item:set_finished()
  end)

end)
