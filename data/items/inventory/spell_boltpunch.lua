local item = ...
local game = item:get_game()

local magic_cost = 15
local windup_time = 300
local damage = 8
local offset = 24

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_backdraft")
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
  hero:set_animation("punch_windup")
  local x, y, z = hero:get_position()
  --[[ portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{255,255,100} --]]
  light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,255,80} --]]

  sol.timer.start(map, windup_time, function()
    --portal_entity:remove()
    light_effect_entity:remove()
    hero:set_animation("punch", function()
      item:create_attacks()
      hero:set_animation"stopped"
      item:set_finished()
    end)
  end)
end)


function item:create_attacks()
  local map = item:get_map()
  local hero = game:get_hero()
  local hx, hy, z = hero:get_position()
  local direction = hero:get_direction()

  local x = hx + game:dx(offset)[direction]
  local y = hy + game:dy(offset)[direction]
  local zap = map:create_lightning{
    x=x, y=y, layer=z
  }
  zap.damage = damage
  zap.harmless_to_hero = true
end

