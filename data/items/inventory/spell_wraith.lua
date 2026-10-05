local item = ...
local game = item:get_game()

local heal_amount = 8
local magic_cost = 80

local wraith_lifespan = 8000 --how long wraith will last
local wraith_range = 200
local wraith_melee_range = 40
local wraith_damage = 4

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_wraith")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)
 
item:register_event("on_using", function(self)
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  hero:set_animation("kneeling")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{230,100,180}

  sol.timer.start(map, 1000, function()
    portal_entity:remove()
    item:create_wraith()

    hero:set_animation"stopped"
    item:set_finished()
  end)
end)



function item:create_wraith()
  local map = game:get_map()
  local hero = map:get_hero()
  local direction = hero:get_direction()
  local x, y, z = hero:get_position()
  x = x + game:dx(16)[direction]
  y = y + game:dy(16)[direction]
  map:create_poof(x, y + 1, z)
  local wraith = map:create_custom_entity{
    x = x, y = y, layer = z,
    width = 16, height = 16, direction = direction,
    sprite = "enemies/trillium_enemies/wraith"
  }

  wraith:set_drawn_in_y_order(true)
  wraith:set_traversable_by(false)
  wraith:set_traversable_by("hero", true)
  wraith:set_can_traverse(true)
  wraith:set_can_traverse_ground("shallow_water", true)
  wraith:set_can_traverse_ground("hole", true)
  wraith:set_can_traverse_ground("lava", true)
  wraith:set_can_traverse_ground("wall", true)
  wraith:set_can_traverse_ground("low_wall", true)

  --Set lifespan
  sol.timer.start(wraith, wraith_lifespan, function()
    wraith:stop_movement()
    sol.timer.stop_all(wraith)
    wraith:get_sprite():fade_out()
    sol.timer.start(wraith, 500, function()
      wraith:remove()
    end)
  end)


  function wraith:on_movement_changed(m)
    wraith:get_sprite():set_direction(m:get_direction4())
  end


  function wraith:choose_enemy()
    local x, y, z = wraith:get_position()
    local possible_enemies = {}
    for e in map:get_entities_in_rectangle(x - wraith_range, y - wraith_range, wraith_range * 2, wraith_range * 2) do
      if e:get_type() == "enemy" then
        table.insert(possible_enemies, e)
      end
    end
    if not possible_enemies[1] then
      wraith:wander()
    else
      local rand = math.random(1, #possible_enemies)
      local chosen_enemy = possible_enemies[rand]
      wraith:target_enemy(chosen_enemy)
    end
  end


  function wraith:wander()
    local m = sol.movement.create"random"
    m:start(wraith)
    sol.timer.start(wraith, 1000, function()
      wraith:choose_enemy()
    end)
  end


  function wraith:target_enemy(target_enemy)
    local m = sol.movement.create"target"
    m:set_target(target_enemy)
    m:set_speed(80)
    m:start(wraith)
    sol.timer.start(wraith, 50, function()
      if wraith:get_distance(target_enemy) <= wraith_melee_range then
        m:stop()
        wraith:attack(target_enemy)
      else
        return true
      end
    end)
  end


  function wraith:attack(target_enemy)
    local collided_entities = {}
    local direction = wraith:get_direction4_to(target_enemy)
    local sprite = wraith:get_sprite()
    local attack_sprite = wraith:create_sprite"enemies/trillium_enemies/weapons/generic_slash"
    sprite:set_direction(direction)
    attack_sprite:set_direction(direction)
    sol.audio.play_sound("sword3")
    attack_sprite:set_animation("slash_attack")
    sprite:set_animation("slash_attack", function()
      collided_entities = {}
      sol.audio.play_sound("sword3")
      attack_sprite:set_animation"backslash_attack"
      sprite:set_animation("backslash_attack", function()
        wraith:remove_sprite(attack_sprite)
        sprite:set_animation"walking"
        sol.timer.start(wraith, 300, function()
          if target_enemy:get_life() > 0 then
            wraith:target_enemy(target_enemy)
          else
            wraith:choose_enemy()
          end
        end)
      end)
    end)
    wraith:add_collision_test("sprite", function(wraith, other, colliding_sprite, other_sprite)
      if not collided_entities[other] and (colliding_sprite == attack_sprite) and (other:get_type() == "enemy") then
        collided_entities[other] = other
        other:hurt(wraith_damage)
      end
    end)
  end

  wraith:choose_enemy()

end
