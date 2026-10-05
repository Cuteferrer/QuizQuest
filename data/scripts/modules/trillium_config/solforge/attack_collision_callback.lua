--Created by Max Mraz and J. Cournoyer, licensed with the MIT license
--This script manages what happens when a solforge weapon hits something.
--Alter this script in whatever way suits your game, default behavior provided will hurt enemies
--The solforge weapon is passed to the process_collision function as item, and the attack that collided as attack

--Some additional notes:
--Weapons can define a `item:enemy_hit_callback(enemy)` function for when enemies are hit
--Each attack can additionally define an `attack:enemy_hit_callback(enemy, damage)` function. This will be called in ADDITION to normal damage, etc.

local manager = {}

function manager:process_collision(props)
  local game = props.game
  local map = props.map
  local hero = props.hero
  local item = props.item --the item itself
  local attack = props.attack --the current attack
  local weapon_entity = props.weapon_entity --the custom entity of the weapon
  local other_entity = props.other_entity --the entity registering the sprite collision
  local weapon_sprite = props.weapon_sprite --the sprite of the weapon entity
  local other_sprite = props.other_sprite --the sprite of the other entity


  --Allow any entity to define its own behavior when getting hit:
  --For example, if you have a custom entity that can be destroyed, you can use this method
  if other_entity.react_to_solforge_weapon then other_entity:react_to_solforge_weapon(item) end

  --ENEMY
  --In this implementation, I'm expecting weapon attacks to have an `attack_power` attribute
  --We also accept attacks to maybe have an attack to`attack_power_bonus` value to be added to the attack power.
  if other_entity:get_type() == "enemy" then
    --Don't hurt enemies that are allies:
    if other_entity.faction == "hero" then return end

    --Ignore enemies in another room:
    if not other_entity:is_in_same_region(hero) then return end
    --Ignore enemy if not visible:
    if not other_entity:is_visible() then return end

    local base_attack_power = (game:get_value(item.item_id .. "_attack_power") or 1) + (attack.attack_power_bonus or 0)
    local damage_type = (game:get_value(item.item_id .. "_damage_type") or "physical")
    local stagger_value = (game:get_value(item.item_id .. "_stagger_value") or 0)

    local attack_power = base_attack_power --might modify this in the future
    

    --Following function will take into account enemy's attack consequence settings,etc.
    manager:initiate_attack_consequence(other_entity, item, weapon_entity, attack_power, damage_type, stagger_value)

    --Allow attacks to have a custom additional consequence
    if attack.enemy_hit_callback then
      attack.enemy_hit_callback(other_entity, attack_power)
    end

   --Check if the enemy should push the hero back when struck; if so, move hero away from enemy slightly.
    if other_entity:get_push_hero_on_sword() then
      hero:stop_movement()
      local m = sol.movement.create"straight"
      m:set_speed(128)
      m:set_max_distance(64)
      m:set_angle(other_entity:get_angle(hero))
      m:start(hero)
    end
    --Rumble controller
    game:rumble("melee_hit")

  end


  --DESTRUCTIBLE
  if other_entity:get_type() == "destructible" then
    local x,y,z = other_entity:get_position()

    --If it blows up, explode it
    if other_entity:get_can_explode() then
      map:create_explosion{x=x, y=y, layer=z}
      sol.audio.play_sound"explosion"
      if other_entity.on_exploded then other_entity:on_exploded() end
      other_entity:remove()

    --If it can be cut, cut it
    elseif other_entity:get_can_be_cut() then
      if other_entity:get_destruction_sound() then
        sol.audio.play_sound(other_entity:get_destruction_sound())
      end
      if other_entity:get_treasure() then
        local tname, tvar, tsave = other_entity:get_treasure()
        map:create_pickable{
          x=x, y=y, layer=z,
          treasure_name = tname, treasure_variant = tvar, treasure_savegame_variable = tsave,
        }
      end
      if other_sprite:has_animation("destroy") then
        other_sprite:set_animation("destroy", function()
          other_entity:remove()
        end)
      else
        other_entity:remove()
      end
      if other_entity.on_cut then other_entity:on_cut() end
    end
    --Rumble controller
    game:rumble("melee_hit")
  end


  --SWITCH
  --Note: due to lack of accessor methods, there's no way to know if a switch is solid or arrow type
  --Therefore, this toggles ALL switches (other than walkable), even arrow type
  --Arrow type is a bit depricated anyway, as they only respond to built-in arrows. Custom arrows have no way to know either.
  if other_entity:get_type() == "switch"
    and not other_entity:is_walkable() then
    local switch = other_entity
    sol.audio.play_sound("switch")
    switch:set_activated(not switch:is_activated())
    if switch:is_activated() then
      other_sprite:set_animation("activated")
      if switch.on_activated then switch:on_activated() end
    else
      other_sprite:set_animation("inactivated")
      if switch.on_inactivated then switch:on_inactivated() end
    end
  end


  --Flip Crystal switches
  if other_entity:get_type() == "crystal" and not other_entity.solforge_activation_cooldown then
    sol.audio.play_sound("switch")
    map:change_crystal_state()
  end

end


local blade_contact_sounds = {
  "blade_hit_01",
  "blade_hit_02",
  "blade_hit_03",
  "blade_hit_04",
  "blade_hit_05",
  "blade_hit_06",
}


--Hurt enemies
function manager:initiate_attack_consequence(enemy, item, weapon_entity, attack_power, damage_type, stagger_value)
  local game = enemy:get_game()
  local hero = game:get_hero()
  local item_id = item.item_id
  local attack_consequence = enemy:get_attack_consequence"sword"

  --allow weapons to define a callback for hitting an enemy, good for applying status effects, etc
  if item.enemy_hit_callback then
    item:enemy_hit_callback(enemy)
  end

  --Trigger event for charms to catch
  game.event_manager:trigger_event("on_enemy_attacked", enemy, attack_power)

  --TODO: allow weapons to overwrite this with their own set of sound effects:
  if type(attack_consequence) == "number" then
    local sound_set = blade_contact_sounds
    sol.audio.play_sound(sound_set[math.random(1, #sound_set)])
  end


  --Shake the screen a bit when you hit one
  game:get_map():get_camera():shake{shake_count = 4, zoom_scale = 1, amplitude = 1,}  

  --allow enemies to define their own getting hurt methods
  if enemy.process_hit then
    enemy:process_hit({damage = attack_power, damage_type = damage_type, stagger_value = stagger_value})
  elseif type(attack_consequence) == "number" then
    enemy:hurt(attack_power)
  elseif type(attack_consequence) == "function" then
    attack_consequence()
  else
    --If the attack_consequence is not a number or a function, then it is a string.
    if attack_consequence == "ignored" then
      --Do nothing. Enemy ignores the collision and damage.
    elseif attack_consequence == "protected" then
      if game:get_value(item_id .. "_attack_blocked_animation") and game:get_value(item_id .. "_attack_blocked_sound") then 
        weapon_entity:get_sprite():set_animation(game:get_value(item_id .. "_attack_blocked_animation"))
        sol.audio.play_sound(game:get_value(item_id .. "_attack_blocked_sound"))
      end
    elseif attack_consequence == "immobilized" then
      enemy:immobilize()
    elseif attack_consequence == "custom" then
      enemy:hurt(attack_power)
    end   --End the string if block.

  end   --End the type() if block.

end






return manager