--[[
Created by Max Mraz, licensed MIT

Ceiling Fall:
Allows an entity to fall from "the ceiling" of the map.
Use: call entity:fall([props])  (props is optional)
Props table values:
callback: a function, callback for when fall is done
speed: between 1 and 100 (default 100)
distance: how far above its position the entity falls from (default 300px)
step: how much the entity moves per distance ms (default ??)
angle: unused
max_bounces: how many times should it bounce when it lands
max_bounce_height: how high should it bounce


Hole Fall: Call when an entity is over a hole to remove it with an animation and sound
entity:fall_down_hole(animation)
Animation options are "small", nil (default animation)

Water Fall: Call when an entity is over water to remove it with a splash
entity:fall_in_water(animation)
Animation options are: "small", nil (default animation)
--]]

local hero_meta = sol.main.get_metatable"hero"
local enemy_meta = sol.main.get_metatable"enemy"
local custom_entity_meta = sol.main.get_metatable"custom_entity"

local function fall(entity, props)
  local callback
  --allow props table to be optional param
  if props and type(props) == "function" then
    local c = props
    props = {}
    props.callback = c
  elseif not props then
    props = {}
  end
  local speed = props.speed or 100
  local distance = props.distance or 300
  local step = props.step or 5
  local angle = props.angle or 3 * math.pi / 2
  local max_bounces = props.max_bounces or 0
  local bounces = 0
  local max_bounce_height = props.max_bounce_height or 4
  callback = props.callback or function() end

  local sprite = entity:get_sprite()
  local offset = distance
  sprite:set_xy(0, offset * -1)
  sol.timer.start(entity, 110 - (speed or 100), function()
    offset = offset - step
    if offset < 0 then offset = 0 end
    sprite:set_xy(0, offset * -1)
    if offset > 0 then
      return true
    elseif bounces < max_bounces then
      offset = max_bounce_height
      sprite:set_xy(0, offset * -1)
      max_bounce_height = math.max(max_bounce_height - 2, 1)
      bounces = bounces + 1
      return true
    else
      if callback then callback() end
    end
  end)
end

hero_meta.fall = fall
enemy_meta.fall = fall
custom_entity_meta.fall = fall



--Fall in Hole
local function fall_down_hole(entity, animation)
  local map = entity:get_map()
  local x, y, z = entity:get_position()
  entity:remove()
  local star = map:create_custom_entity{
    x = x, y = y, layer = z, direction = 0,
    width = 16, height = 16,
    sprite = "entities/fall_in_hole_star",
    model = "ephemeral_effect",
  }
  if animation then
    local sprite = star:get_sprite()
    if not sprite:has_animation(animation) then error("Error: no animation " .. animation .. " found for falling in hole star: 'entities/fall_in_hole_star'") end
    sprite:set_animation(animation)
  end
  sol.audio.play_sound("falling_on_hole")
end

hero_meta.fall_down_hole = fall_down_hole
enemy_meta.fall_down_hole = fall_down_hole
custom_entity_meta.fall_down_hole = fall_down_hole



--Fall in Water
local function fall_in_water(entity, animation)
  local map = entity:get_map()
  local x, y, z = entity:get_position()
  entity:remove()
  local star = map:create_custom_entity{
    x = x, y = y, layer = z, direction = 0,
    width = 16, height = 16,
    sprite = "entities/fall_in_water_splash",
    model = "ephemeral_effect",
  }
  if animation then
    local sprite = star:get_sprite()
    if not sprite:has_animation(animation) then error("Error: no animation " .. animation .. " found for falling in hole star: 'entities/fall_in_hole_star'") end
    sprite:set_animation(animation)
  end
  sol.audio.play_sound("splash")
end

hero_meta.fall_in_water = fall_in_water
enemy_meta.fall_in_water = fall_in_water
custom_entity_meta.fall_in_water = fall_in_water




--Apply these methods to all entities:
sol.all_entities_manager.apply_to_entities("fall", fall)
sol.all_entities_manager.apply_to_entities("fall_down_hole", fall_down_hole)
sol.all_entities_manager.apply_to_entities("fall_in_water", fall_in_water)

