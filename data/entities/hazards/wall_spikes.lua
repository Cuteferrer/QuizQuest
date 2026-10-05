local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  entity.range = entity:get_property("range") or 80
  entity.trigger_sound = entity:get_property("trigger_sound") or "switch"
  entity.trigger_delay = entity:get_property("trigger_delay") or 100
  entity.attack_sound = entity:get_property("attack_sound") or "weapons/blunt_02"
  entity.attack_sprite = entity:get_property("attack_sprite")
  entity.damage = entity:get_property("damage") or 15
  entity.damage_type = entity:get_property("damage_type") or "physical"
  entity.cooldown_duration = entity:get_property("cooldown_duration") or 3000
  entity:set_visible(entity:get_property("invisible") and false or true)

  local direction = entity:get_direction()
  local x, y, z = entity:get_position()
  local sw, sh = 16, 16
  local dx, dy = 0, 0
  if direction == 0 then
    sw = entity.range
  elseif direction == 1 then
    sh = entity.range
    dy = (entity.range - 16) * -1
  elseif direction == 2 then
    sw = entity.range
    dx = (entity.range - 16) * -1
  elseif direction == 3 then
    sh = entity.range
  end


  --Create trigger sensor:
  local trigger_sensor = map:create_sensor{
    x=x + dx, y=y + dy, layer=z, width = sw, height = sh,
  }

  function trigger_sensor:on_activated()
    if not entity.trigger_cooldown then
      entity:trigger_spikes()
    end
  end
end


function entity:trigger_spikes()
  entity.trigger_cooldown = true
  sol.timer.start(entity, entity.cooldown_duration, function()
    entity.trigger_cooldown = false
  end)

  entity:make_sound(entity.trigger_sound)
  sol.timer.start(entity, entity.trigger_delay, function()
    entity:attack()
  end)
end


function entity:attack()
  local x, y, z = entity:get_position()
  local direction = entity:get_direction()
  local attack_sprite = entity.attack_sprite or entity:get_sprite():get_animation_set()
  local attack = map:create_custom_entity{
    x=x, y=y, layer=z, direction=direction, width=16, height=16,
    sprite = attack_sprite,
    model = "enemy_projectiles/general_attack",
  }
  attack.damage = entity.damage
  attack.damage_type = entity.damage_type
  attack:get_sprite():set_animation("activated")
  attack:remove_after_animation()
end



