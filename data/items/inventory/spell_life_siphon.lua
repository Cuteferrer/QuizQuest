local item = ...
local game = item:get_game()

local heal_amount = 8
local magic_cost = 25
local windup_time = 200
local damage = 4

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_life_siphon")
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
  local direction = hero:get_direction()
  hero:set_animation("casting")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{150,0,150}
  --[[ light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100} --]]

  sol.timer.start(map, windup_time, function()
    portal_entity:remove()
    hero:set_animation("sword", function()
      item:set_finished()
    end)
    local siphon = map:create_custom_entity{
      x = x, y = y, layer = z,
      width = 16, height = 16, direction = 0,
      sprite = "items/life_siphon"
    }
    local siphon_sprite = siphon:get_sprite()
    siphon_sprite:set_animation("siphon", function()
      siphon:remove()
    end)
    siphon_sprite:set_rotation(direction * math.pi / 2)
    siphon:set_drawn_in_y_order(true)
    local collided_entities = {}
    siphon:add_collision_test("sprite", function(siphon, other)
--TODO: this collision is super unreliable? What's going on?
      if collided_entities[other] then return end
      collided_entities[other] = true
      if other:get_type() == "enemy" then
        local enemy = other
        if enemy.process_hit then enemy:process_hit(damage)
        else enemy:hurt(damage) end
        game:add_life(damage / 2)
      end
    end)
  end)
end)
