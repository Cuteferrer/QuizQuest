--[[
Created by Max Mraz, licensed MIT
A proximity mine, can be activated by either the hero, enemies, or either
Values you can set:
  entity.explosion_sprite : sprite of the explosion created
  entity.range = entity.range : how close targets can get before the mine is triggered
  entity.fuse_length = entity.fuse_length : how long after being triggered before the mine goes off
  entity.ignore_enemies = entity.ignore_enemies : if true, enemies won't set off this mine. Useful for traps to catch the player
  entity.ignore_hero = entity.ignore_hero or false : if true, the hero won't set off this mine. Useful if the hero is placing these
  entity.explosion_callback = a function: callback function that will be called when the explosion goes off
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity.range = entity.range or 24
  entity.fuse_length = entity.fuse_length or 500
  entity.ignore_enemies = entity.ignore_enemies or true
  entity.ignore_hero = entity.ignore_hero or false
  entity.triggered = false

  sol.timer.start(entity, 100, function()
    local x, y, z = entity:get_position()
    local range = entity.range
    for e in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
      if e:get_type() == "enemy" and not entity.ignore_enemies and entity:get_distance(e) <= range then
        entity:start_countdown()
      elseif e:get_type() == "hero" and not entity.ignore_hero and entity:get_distance(e) <= range then
        entity:start_countdown()
      end
    end
    return not entity.triggered
  end)
end


function entity:start_countdown()
  sol.audio.play_sound"switch"
  sol.audio.play_sound"device_set"
  sol.timer.stop_all(entity)
  entity.triggered = true
  sol.timer.start(entity, entity.fuse_length, function()
    local x, y, z = entity:get_position()
    entity:remove()
    local explosion = map:create_explosion{
      x=x, y=y, layer=z,
      sprite = entity.explosion_sprite or "items/explosion_grenade",
    }
    if entity.ignore_hero then
      explosion.hero_damage = 0
    end
    if entity.explosion_callback then
      entity.explosion_callback(entity)
    end
  end)
end


function entity:react_to_fire()
  entity:start_countdown()
end

function entity:react_to_explosion()
  entity:start_countdown()
end
