local item = ...
local game = item:get_game()

local magic_cost = 75
local windup_time = 400
local damage = 10
local shockwave_frequency = 500
local max_shockwaves = 4

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_mending_tree")
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
  hero:set_animation("touching_ground")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,255,255}
  --[[light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{150,255,150}--]]

  sol.timer.start(map, windup_time, function()
    map:screenshake({
      shake_count = 70,
      speed = 30,
      amplitude = 1,
      zoom_scale = 1.02
    })

    local shockwaves = 0
    sol.timer.start(hero, shockwave_frequency, function()
      if shockwaves >= max_shockwaves then
        portal_entity:remove()
        hero:unfreeze()
      else
        item:create_shockwave(x, y, z)
        shockwaves = shockwaves + 1
        return shockwave_frequency
      end
    end)
  end)
end)


function item:create_shockwave(x, y, z)
  local map = item:get_map()
  local sprite_id = "enemies/trillium_enemies/shockwave_8x7"
  local shockwave = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16, sprite=sprite_id, model="damaging_entity",
  }
  shockwave:get_sprite():set_opacity(100)
  shockwave:get_sprite():set_scale(1.5, 1.5)
  shockwave.damage = damage
end

