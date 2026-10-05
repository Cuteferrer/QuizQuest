--Created by Max Mraz and J. Cournoyer, licensed with the MIT license
--See example weapons for examples.
--Minimum viable weapon is:
--local item = ...
--require("items/solforge/forge"):new_weapon(item)
--That will give you an item with all the default values

--Default behavior is defined in attack_collision_callback.lua, feel free to overwrite that to suit your game

local weapon_factory = {}
local collision_callback_manager = require("scripts/modules/trillium_config/solforge/attack_collision_callback")
local weapon_use_manager = require"scripts/modules/trillium_config/solforge/weapon_use_callback"
local use_cost_manager = require"scripts/modules/trillium_config/solforge/use_cost_manager"

local post_attack_combo_window = 400 --how long after an attack before the next move won't be part of a combo

--Applies solforge properties to the item supplied, based on the properties supplied:
function weapon_factory:temper_weapon(item, props)

  local parameters =  props.weapon_parameters

  function item:on_started()
    item.item_id = props.item_id or item:get_name():gsub("/", "_")
    local savegame_variable = "possession_sf_" .. item.item_id
    item:set_savegame_variable(savegame_variable)

    item:set_assignable(true)

    item:set_properties(props)
  end

  function item:set_properties(props)
    local game = item:get_game()
    if props == nil then props = {} end

    --item.callback is a function that is called whenever using the item
    item.callback = props.callback or nil

    --Add a parameter to determine the draw order. True by default if not defined in properties table.
    item.drawn_in_y_order = props.drawn_in_y_order or true

    --item.attacks is a table of attacks, each of which is a table specifying hero and weapon animations, sound, and damage
    --attack_power_bonus is optional, its an amount to add to the weapon's base attack power for this attack
    --It is only processed in attack_collision_callback, so can be altered there however you want
    --You can also define any number of values for an attack, and use them in attack_collision_callback however you want
    --multiple attacks in item.attacks means a combo
    item.attacks = props.attacks or {
      {
        hero_attack_animation = "sword_swing",
        weapon_sprite = "hero/sword1",
        weapon_attack_animation = "sword",
        weapon_sound = "sword1",
        attack_power_bonus = nil,
      }
    }

    --Save weapon parameters as savegame values, so you can modify them if needed
    for k,v in pairs(parameters or {}) do
      if game:get_value(item.item_id .. "_" .. k) == nil then
        item.k = v
        assert(type(v) == "number" or "string" or "bool", "Item value of key: " .. k .. " is not a number, string, or boolean value.")
        game:set_value(item.item_id .. "_" .. k, v )
      else
        --Quick access shortcut:
        item.k = game:get_value(item.item_id .. "_" .. k)
      end
    end

  end


  function item:on_using(windup_duration_override)
    local map = item:get_map()
    local hero = map:get_hero()
    local game = map:get_game()
    local combo_number = hero.combo_number or 1
    local x, y, z = hero:get_position()
    local direction = hero:get_direction()
    if hero.weapon_entity then hero.weapon_entity:remove() end

    --Check if the weapon needs a resource (magic, stamina, etc.)
    local can_use = item:check_use_cost()

    if not can_use then
      item:set_finished()
      return
    end

    --Reset combo number if we've passed it for this weapon (this is possible if you switch to a weapon with less moves mid-combo)
    if not item.attacks[combo_number] then
      combo_number = 1
      hero.combo_number = 1
    end

    --Turn hero to face direction held - prevents getting stuck attacking away from enemy
    --Relies on controls_manager
    local new_dir
    local input_type =  sol.controls.get_controls_manager().get_active_input_type()
    if sol.controls.get_main_controls and input_type ~= "keyboard" then
      local controls = sol.controls.get_main_controls()
      local held_angle = controls:get_angle() --returns nil if no angle is being held on the joypad
      new_dir = held_angle and sol.main.get_direction4(held_angle) or direction
    elseif game.get_direction_held and input_type == "keyboard" then
       new_dir = game:get_direction_held() / 2 --get_direction_held() returns a dir8
    end
    if direction ~= new_dir then
      hero:set_direction(new_dir)
      direction = new_dir
    end

    --Create the weapon as a custom entity:
    hero.weapon_entity = map:create_custom_entity{
      x = x, y = y, layer = z,
      direction = direction, width = 16, height = 16,
      sprite = item.attacks[combo_number].weapon_sprite,
    }
    --Set the weapon draw order based on the item.drawn_in_y_order value.
    hero.weapon_entity:set_drawn_in_y_order(item.drawn_in_y_order)

    --Put player into custom attack state while attacking
    hero:start_state(item:get_attack_state())

    --Prevent combo number from changing after we start a windup
    if item.combo_timer then item.combo_timer:stop() end

    --Set hero and weapon in windup animations:
    local attack = item.attacks[combo_number]
    attack.windup_duration = windup_duration_override or attack.windup_duration or 0
    if skip_windup then
      item:start_attack()
    elseif attack.windup_duration > 0 then
      hero:set_animation(attack.hero_windup_animation)
      if attack.windup_sound then sol.audio.play_sound(attack.windup_sound) end
      hero.weapon_entity:get_sprite():set_animation(attack.weapon_windup_animation)
      hero.solforge_attack_windup_timer = sol.timer.start(hero, attack.windup_duration, function()
        item:start_attack()
        hero.solforge_attack_windup_timer = nil
      end)
    else
      item:start_attack()
    end
  end


  function item:attack_without_windup()
    item:on_using(0)
  end



  function item:start_attack(attack)
    local map = item:get_map()
    local hero = map:get_hero()
    local game = map:get_game()
    local combo_number = hero.combo_number or 1
    attack = attack or item.attacks[combo_number]
    local x, y, z = hero:get_position()
    local direction = hero:get_direction()
    hero.weapon_entity:get_sprite():set_animation(attack.weapon_attack_animation, function()
      hero.weapon_entity:remove()
      hero.weapon_entity = nil
    end)

    weapon_use_manager:initiate_usage(item, attack)
    hero.weapon_entity.collided_entities = {}

    --What happens when the attack hits stuff is defined in attack_collision_callback.lua
    hero.weapon_entity:add_collision_test("sprite", function(weapon_entity, other_entity, sprite, other_sprite)
      --Dedup check
      if hero.weapon_entity.collided_entities[other_entity] then return end
      hero.weapon_entity.collided_entities[other_entity] = true

      collision_callback_manager:process_collision({
        weapon_entity = weapon_entity,
        other_entity = other_entity,
        weapon_sprite = sprite,
        other_sprite = other_sprite,
        item = item,
        attack = attack,
        game = game,
        map = map,
        hero = hero,
      })
    end)

    --Also check for overlapping collision, making its 16x16 hitbox overlapping the hero also hit enemies
    hero.weapon_entity:add_collision_test("overlapping", function(weapon_entity, other_entity)
      --Dedup check
      if hero.weapon_entity.collided_entities[other_entity] then return end
      hero.weapon_entity.collided_entities[other_entity] = true

      collision_callback_manager:process_collision({
        weapon_entity = weapon_entity,
        other_entity = other_entity,
        weapon_sprite = weapon_entity:get_sprite(),
        other_sprite = other_entity:get_sprite(),
        item = item,
        attack = attack,
        game = game,
        map = map,
        hero = hero,
      })
    end)

    sol.audio.play_sound(attack.weapon_sound or "sword1")


    hero:set_animation(attack.hero_attack_animation, function()
      if attack.recovery_duration then
        hero:set_animation(attack.hero_recovery_animation)
        hero.solforge_attack_recovery_timer = sol.timer.start(hero, attack.recovery_duration, function()
          hero:unfreeze()
          item:set_finished() 
          hero.solforge_attack_recovery_timer = nil
        end)
      else
        hero:unfreeze()
        item:set_finished() 
      end
    end)

    --Call item and attack callbacks, if any
    if item.callback then item.callback() end
    if attack.callback then attack.callback() end

    --Manage attack combo iteration:
    if item.combo_timer then item.combo_timer:stop() end --remove previous timer
    hero.combo_number = combo_number + 1
    if hero.combo_number > #item.attacks then hero.combo_number = 1 end --return to attack 1 if max is reached
    --Set the window for the next attack to 200ms after the animation finishes
    local timer_length = attack.windup_duration + hero.weapon_entity:get_sprite():get_num_frames() * hero.weapon_entity:get_sprite():get_frame_delay() + post_attack_combo_window
    item.combo_timer = sol.timer.start(map, timer_length, function()
      hero.combo_number = 1
    end)
  end


  --Check if the hero has enough of any resource to use the weapon, and remove the cost, if applicable
  function item:check_use_cost()
    local can_use = use_cost_manager.can_use(item)

    return can_use
  end


  --Custom attack state
  function item:get_attack_state()
    local state = sol.state.create()
    state:set_visible(true)
    state:set_can_control_direction(false)
    state:set_can_control_movement(false)
    state:set_gravity_enabled(true)
    state:set_can_come_from_bad_ground(true)
    state:set_can_be_hurt(true)
    state:set_can_use_sword(false)
    state:set_can_use_shield(false)
    state:set_can_use_item(false)
    state:set_can_interact(false)
    state:set_can_grab(false)
    state:set_can_push(false)
    state:set_can_pick_treasure(true)
    state:set_can_use_teletransporter(false)
    state:set_can_use_switch(true)
    state:set_can_use_stream(true)
    state:set_can_use_stairs(true)
    state:set_can_use_jumper(false)
    state:set_carried_object_action("throw")
    return state
  end

  return item

end


--Keep weapon anchored on hero, if they're moved by enemy attacks, streams, etc
local hero_meta = sol.main.get_metatable("hero")
hero_meta:register_event("on_position_changed", function(self, x, y, z)
  if self.weapon_entity and self.weapon_entity:exists() then
    self.weapon_entity:set_position(x, y, z)
  end
end)

--Remove the weapon if the player is hit, so it doesn't keep animating on its own
hero_meta:register_event("on_taking_damage", function(self)
  local hero = self
  if hero.weapon_entity and hero.weapon_entity:exists() then
    hero.weapon_entity:remove()
  end
end)


--Stops any attack that is currently in-progress
function hero_meta:stop_solforge_attack()
  local hero = self
  if hero.solforge_attack_windup_timer then hero.solforge_attack_windup_timer:stop() end
  if hero.solforge_attack_recovery_timer then hero.solforge_attack_recovery_timer:stop() end
  if hero.weapon_entity and hero.weapon_entity:exists() then
    hero.weapon_entity:remove()
  end
end


return weapon_factory

