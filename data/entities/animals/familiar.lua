--[[
Created by Max Mraz, licensed MIT
An animal familiar that will follow the hero around and attack nearby enemies

After creating the familiar, call familiar:start() to get it to start wandering around and attacking

A familiar can be given a custom attack by defining a range to entity.custom_attack_range as well as defining a function:
    function entity:custom_attack(enemy)
      --do your attack to the targeted enemy
    end
The custom attack will be executed if the familiar is within familiar.aggro_range and familiar.custom_attack_range

Notes:
set entity_sprite.harmless to give the entity non-attacking sprites (like a shadow or something)
set entity.harmless_collision = true to totally disable collision damage (and depend on custom attacks or something)

Recommendations:
These familiars can easily get stuck on walls when trying to follow after the hero (or anytime, their movement is very simple),
so I'd recommend treating them as a ephemeral spell effect, not lasting much longer than 10 seconds
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local sprite

function entity:on_created()
  sprite = entity:get_sprite()

  entity.damage_cooldown = 1500
  entity.damage = 1
  entity.damage_type = "physical"
  entity.duration = 10000
  entity.idle_speed = 60
  entity.hero_radius = 64 --how close to stay to the hero
  entity.follow_hero_speed = 140
  entity.follow_hero_pass_walls = false --don't recommend this, easy way to get even more stuck in walls
  entity.wander_duration = 1000 --how long before checking for enemies
  entity.aggro_range = 100 --how close to get before attacking an enemy
  entity.possible_enemies = 4 --of the X closest enemies, choose randomly
  entity.target_enemy_speed = 80 --how fast we go after an enemy
  entity.harmless_collision = false
  entity.collision_callback = nil --set this as a function that will be called when colliding with an enemy, passing the enemy as an argument

  entity:set_drawn_in_y_order(true)

  --Fade away after duration
  sol.timer.start(entity, 10, function() --wrap in another timer so the code that calls it has time to set entity.duration before this timer starts
    sol.timer.start(entity, entity.duration, function()
      sol.timer.stop_all(entity)
      local m = entity:get_movement()
      if m then m:stop() end
      sprite:fade_out()
      sol.timer.start(entity, 1000, function() entity:remove() end)
    end)
  end)

  --Don't tread on other entities:
  entity:set_can_traverse("custom_entity", function(entity, other)
    if other:get_model() == "animals/familiar" then
      if entity:overlaps(other) then return true
      else return false end
    else
      return true
    end
  end)

  --Add collision to hurt enemies
  entity.collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other, sprite, other_sprite)
    if entity.harmless_collision then return end
    if sprite.harmless then return end --for entities with multiple sprites
    if other:get_type() == "enemy" and not entity.collided_entities[other] then
      entity.collided_entities[other] = other
      sol.timer.start(entity, entity.damage_cooldown or 2000, function() entity.collided_entities[other] = nil end)
      if other.process_hit then
        other:process_hit({damage = entity.damage or 1, damage_type = entity.damage_type or "physical"})
      else
        other:hurt(entity.damage or 1)
      end

      if entity.collision_callback then
        entity:collision_callback(other)
      end
    end
  end)

end


--Face direction of movement
function entity:on_movement_changed(m)
  local dir4 = m:get_direction4()
  local angle = m:get_angle()
  local sds = sprite:get_num_directions()
  if sds == 4 then
    sprite:set_direction(dir4)
  elseif sds == 2 then
    sprite:set_direction( (angle > math.pi / 2 or angle < 3 * math.pi / 2) and 1 or 0 )
  end
end


function entity:start()
  entity:find_enemy()
end


--Wander randomly:
function entity:wander()
  local map = entity:get_map()
  local hero = map:get_hero()
  sprite:set_animation("walking")
  if entity:get_distance(hero) >= entity.hero_radius then
    local m = sol.movement.create"target"
    m:set_target(hero)
    m:set_speed(entity.follow_hero_speed)
    if entity.follow_hero_pass_walls then m:set_ignore_obstacles(true) end
    m:start(entity)
  else
    local m = sol.movement.create("random")
    m:set_speed(entity.idle_speed)
    m:start(entity)
  end
  sol.timer.start(entity, entity.wander_duration, function()
    entity:find_enemy()
  end)
end


--Attack an enemy if nearby:
function entity:find_enemy()
  local enemies = entity:select_nearby_enemies(entity.aggro_range, entity.possible_enemies) --get x closest enemies
  local enemy = enemies[math.random(1, #enemies)]
  if not enemy then
    entity:wander()
    return
  end
  sprite:set_animation("walking")
  local m = sol.movement.create"target"
  m:set_target(enemy)
  m:set_speed(entity.target_enemy_speed)
  m:start(entity)

  function m:on_position_changed()
    local dist = entity:get_distance(enemy)
    if entity.custom_attack and dist <= entity.custom_attack_range then
      entity:custom_attack(enemy)
    elseif dist <= 6 then
      m:stop()
      entity:wander()
      sol.timer.start(entity, 1000, function()
        entity:find_enemy()
      end)
    end
  end
end

