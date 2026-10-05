local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity.frequency = entity:get_property"frequency" or 4000
  entity.init_delay = entity:get_property"init_delay" or 0
  entity.enemy_damage = entity:get_property("enemy_damage") or entity:get_property("damage") or 100
  entity.hero_damage = entity:get_property("hero_damage") or entity:get_property("damage") or 20

  --Create slammer entity (hitbox):
  local x, y, z = entity:get_position()
  local width, height = entity:get_size()
  local dir = entity:get_direction()
  local ox, oy = entity:get_origin()
  local slammer = map:create_custom_entity{
    x=x, y=y, layer=z, width=width, height=height, direction=dir,
  }
  slammer:set_origin(ox, oy)
  slammer:set_traversable_by(false)
  slammer:set_traversable_by("hero", function(slammer, other) return slammer:overlaps(other) end)
  slammer:set_traversable_by("enemy", function(slammer, other) return slammer:overlaps(other) end)
  --Collision test:
  entity.collided_entities = {}
  slammer:add_collision_test("touching", function(slammer, other)
    local other_type = other:get_type()
    if other_type == "hero" or other_type == "enemy" then
      entity:push_other(other, dir)
    end
  end)
  slammer:add_collision_test("overlapping", function(slammer, other)
    local other_type = other:get_type()
    if other_type == "hero" or other_type == "enemy" then
      entity:push_other(other, dir)
    end
  end)
  entity.hitbox = slammer

  --Create movement ahead of time as well?
  entity.slam_movement = sol.movement.create"straight"

  entity:set_active(tobool(entity:get_property("active") or true))
end


function entity:set_active(active)
  entity.active = active
  if active then
    entity:activate()
  else
    entity:deactivate()
  end
end


function entity:activate()
  entity.crush_timer = sol.timer.start(entity, entity.init_delay, function()
    entity:crush()
    return entity.frequency
  end)
end


function entity:deactivate()
  if entity.crush_timer then entity.crush_timer:stop() end
end


function entity:crush()
  local dir = entity:get_direction()
  local slammer = entity.hitbox
  --Slam movement:
  local m = entity.slam_movement
  m:set_max_distance(48)
  m:set_angle(dir * math.pi / 2)
  m:set_speed(400)
  m:set_ignore_obstacles(true)
  m:set_smooth(false)
  m:start(slammer, function()
    --return:
    m:set_speed(66)
    m:set_angle((dir * math.pi / 2 + math.pi) % (math.pi * 2))
    m:start(slammer)
  end)

  --Visuals, etc
  local sprite = entity:get_sprite()
  sprite:set_animation("crush", function()
    sprite:set_animation("stopped")
  end)
  if entity:is_on_screen() then
    entity:make_sound("running_obstacle")
  end
end


function entity:push_other(other, dir)
  local angle = dir * math.pi / 2
  local x, y, z = other:get_position()
  local dx, dy = math.cos(angle), math.sin(angle) * -1
  local obstacle = other:test_obstacles(dx, dy)

  --Push:
  if not obstacle then
    other:set_position(x + dx, y + dy, z)
    return
  else
    entity:squish_other(other)
  end

end


function entity:squish_other(other)
  if entity.collided_entities[other] then return end
  entity.collided_entities[other] = true
  sol.timer.start(entity, entity.frequency / 2, function()
    entity.collided_entities[other] = nil
  end)
  local other_type = other:get_type()
  if other_type == "enemy" then
    if other.process_hit then
      other:process_hit({damage = entity.enemy_damage, damage_type = "physical"})
    end

  elseif other_type == "hero" then
    other:process_hit{
      damage = entity.hero_damage,
      damage_type = "physical",
      enemy = entity,
    }
    sol.timer.start(other, 20, function()
      if other:get_life() > 0 then
        entity:return_to_solid_ground(other)
      end
    end)
  end
end


function entity:return_to_solid_ground(hero)
  hero:freeze()
  game:start_flash({0,0,0})
  sol.timer.start(map, 100, function()
    hero:set_position(hero:get_solid_ground_position())
    game:stop_flash(5)
    hero:set_animation("getting_up", function() hero:unfreeze() end)
  end)

  --The hero can get re-crushed while being pulled back to the starting location with this one:
  --It's funny, but a bad experience
  --[[
  hero:freeze()
  hero:set_invincible(true)
  hero:set_visible(false)
  local m = sol.movement.create"target"
  m:set_target(hero:get_solid_ground_position())
  m:set_ignore_obstacles()
  m:set_speed(900)
  m:start(hero, function()
    hero:set_visible(true)
    hero:set_invincible(false)
    hero:set_blinking(true, 1000)
    hero:unfreeze()
  end)
  --]]
end

