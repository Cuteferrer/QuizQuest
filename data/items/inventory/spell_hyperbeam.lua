local item = ...
local game = item:get_game()

local magic_cost = 30
local windup_time = 500
local damage = 25
local beam_duration = 2000

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_hyperbeam")
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
  hero:set_animation("punch_windup")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{100,200,255} --]]
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{100,200,255} --]]

  sol.timer.start(hero, windup_time, function()
    portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation("punch", function()
      hero:set_animation"hookshot"
    end)
    local offset = 8
    local hbx = x + game:dx(offset)[direction]
    local hby = y + game:dy(offset)[direction]

    local beam = map:create_custom_entity{
      x = hbx, y = hby - 4, layer = z,
      width = 16, height = 16, direction = 0,
      model = "damaging_entity",
      sprite = "entities/enemy_projectiles/hyperbeam",
    }
    hero.weapon_entity = beam --this is using functionality from solforge weapons
    beam.damage = damage
    beam.duration = beam_duration
    local beam_sprite = beam:get_sprite()
    beam_sprite:set_scale(1.4, 1.2)
    beam_sprite:set_rotation(direction * math.pi / 2)

    sol.timer.start(hero, beam_duration, function()
      hero:unfreeze()
      item:set_finished()
    end)
  end)


end)







