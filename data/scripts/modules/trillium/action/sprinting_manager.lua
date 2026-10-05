--[[
Created by Max Mraz, licensed MIT
Adds sprinting

Trigger with hero:start_sprinting()
As written, sprinting is stopped when the "dash" button is released, which is obviously a problem
TODO: fix that, that's obviously no good and unconfigurable
--]]

local hero_meta = sol.main.get_metatable"hero"

local speed_boost = 60
local slow_terrain_mod = 30
local running_animation = "running_2"
local invalid_grounds = {
  ["hole"] = true,
  ["deep_water"] = true,
  ["lava"] = true,
}

local state = sol.state.create"sprinting"
state:set_can_control_movement(true)
state:set_can_control_direction(true)


--Determine whether you can sprint:
--Perhaps you need some item to enable it:
function hero_meta:can_sprint()
  local game = self:get_game()
  local hero = game:get_hero()
  local ground = hero:get_ground_below()
  return not invalid_grounds[ground]
end


function hero_meta:start_sprinting()
  local hero = self
  hero:start_state(state)
end


function state:on_started()
  --Note: actual speed increase in handled in on_position_changed rather that modifying walking speed, which was a bit buggy
  local hero = state:get_entity()
  local game = sol.main.get_game()
  local map = hero:get_map()

  --Dust effect:
  local dust_freq = 180
  sol.timer.start(state, dust_freq, function()
    if hero:get_movement() and (hero:get_movement():get_speed() <= 0) then return true end --skip if not moving
    local hx, hy, hz = hero:get_position()
    direction = hero:get_direction()
    local ground = map:get_ground(hx, hy, hz)
    if ground == "traversable" or ground == "grass" or ground == "ladder" or ground == "shallow_water" then
      local dust_cloud = map:create_custom_entity({
        direction = 0, x = hx, y = hy, layer = hz, width = 16, height = 16,
        sprite = "entities/roll_effect",
        model = "ephemeral_effect"
      })
      local dust_sprite = dust_cloud:get_sprite()
      if ground == "shallow_water" then
        dust_sprite:set_animation("ripple")
      end
      dust_sprite:set_direction(math.random(0, dust_sprite:get_num_directions() - 1))
    end
    if state:is_started() then return true end
  end)
end


function state:on_position_changed()
  --Handle speed up increase and different terrains
  local hero = state:get_entity()
  local map = hero:get_map()
  local m = hero:get_movement()
  if not m then return end
  local ground = hero:get_ground_below()
  if ground == "shallow_water" or ground == "ladder" then
    m:set_speed(sol.main.global_constants.HERO_WALKING_SPEED + speed_boost - slow_terrain_mod)
  else
    m:set_speed(sol.main.global_constants.HERO_WALKING_SPEED + speed_boost)
  end
  --Stop state when crossing a separator:
  for e in map:get_entities_in_rectangle(hero:get_bounding_box()) do
    if e:get_type() == "separator" then
      hero:unfreeze()
      break
    end
  end
end


function state:on_command_released(command)
  local hero = state:get_entity()
  if command == "dodge" then
    hero:unfreeze()
  end
end


function state:on_movement_changed(m)
  local hero = state:get_entity()
  if m:get_speed() > 0 then
    hero:set_animation(running_animation)
  else
    hero:set_animation"stopped"
  end
end


