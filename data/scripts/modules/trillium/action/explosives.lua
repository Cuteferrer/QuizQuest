--[[
Created by Max Mraz, licensed MIT
Allows the hero to throw an explosive.
Sprites for explosives can have an animation called "falling", which will play first as its thrown. Then it will play the animation "rolling" if it exists, or else "stopped"

Usage:
hero:throw_explosive(props)
--]]

local hero_meta = sol.main.get_metatable"hero"

function hero_meta:throw_explosive(props)
  local hero = self
  local game = hero:get_game()
  local map = hero:get_map()

  props = props or {}
  local throwing_animation = props.throwing_animation or "throwing"
  local throwing_delay = props.throwing_delay or 270 --delay between throwing animation start and spawning the explosive object/starting its movement. Use to align with animation.
  local sprite = props.sprite or "hero_projectiles/grenade"
  local fuse_duration = props.fuse_duration or 600
  local initial_speed = props.initial_speed or 300
  local speed_loss = props.speed_loss or 40
  local explosion_sound = props.explosion_sound or "explosion_grenade"
  local explosion_sprite = props.explosion_sprite or "items/explosion_grenade"
  local base_damage = props.base_damage or 150
  local enemy_damage = game:calculate_hero_output_damage(base_damage, "alchemy")
  local explosion_props = props.explosion_props or {}
  if not explosion_props.ignore_hero then explosion_props.ignore_hero = true end
  if not explosion_props.enemy_damage then explosion_props.enemy_damage = enemy_damage end
  if not explosion_props.damage_type then explosion_props.damage_type = "physical" end
  local explosion_callback = props.explosion_callback or function(grenade) end

  hero:freeze()
  sol.audio.play_sound"throw"
  hero:set_animation(throwing_animation, function()
    hero:set_animation"stopped"
    hero:unfreeze()
  end)
  sol.timer.start(map, throwing_delay, function()
    local x, y, z = hero:get_position()
    local direction = game:get_direction_held()
    local grenade = map:create_custom_entity{
      x=x, y=y, layer=z,
      width=16, height=16, direction = 0,
      sprite = sprite,
    }

    local grenade_sprite = grenade:get_sprite()
    if grenade_sprite:has_animation"falling" then
      grenade_sprite:set_animation("falling", function()
        grenade_sprite:set_animation(grenade_sprite:has_animation"rolling" and "rolling" or "stopped")
      end)
    end
    grenade:set_can_traverse("hero", true)
    grenade:set_can_traverse("enemy", false)
    grenade:set_can_traverse_ground("hole", true)
    grenade:set_can_traverse_ground("deep_water", true)
    grenade:set_can_traverse_ground("shallow_water", true)

    local m = sol.movement.create"straight"
    m:set_speed(initial_speed)
    m:set_angle(direction * math.pi / 4)
    m:start(grenade)

    local elapsed_time = 0
    local step = 100
    sol.timer.start(grenade, step, function()
      elapsed_time = elapsed_time + step
      if elapsed_time < fuse_duration then
        local new_speed = m:get_speed() - speed_loss
        if new_speed > 0 then
          m:set_speed(new_speed)
        else
          m:set_speed(0)
        end
        return true
      else
        x, y, z = grenade:get_position()
        explosion_callback(grenade)
        grenade:remove()
        local explosion = map:create_explosion{
          x=x, y=y, layer=z, sprite = explosion_sprite,
        }
        for k, v in pairs(explosion_props) do
          explosion[k] = v
        end
        sol.audio.play_sound(explosion_sound)
      end
    end)

    function m:on_position_changed()
      local ground = grenade:get_ground_below()
      if (grenade_sprite:get_animation() ~= "falling") then
        if ground == "hole" then
          sol.timer.stop_all(grenade)
          grenade:stop_movement()
          grenade:fall_down_hole("small")
        elseif ground == "deep_water" then
          sol.timer.stop_all(grenade)
          grenade:stop_movement()
          grenade:fall_in_water("small")
        end
      end
    end
  end)
end

