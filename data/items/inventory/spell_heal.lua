local item = ...
local game = item:get_game()

local heal_amount = 8
local magic_cost = 50

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_heal")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if (game:get_life() >= game:get_max_life()) or not item:try_spend_ammo(magic_cost) then
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
  portal_entity:get_sprite():set_color_modulation{255,150,100}
  --[[ light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{255,150,100} --]]

  sol.timer.start(map, 1000, function()
    portal_entity:remove()
    game:add_life(1)
    local amount_healed = 1
    sol.timer.start(game, 700, function()
      game:add_life(1)
      amount_healed = amount_healed + 1
      if amount_healed < heal_amount then return true end
    end)
    hero:set_animation"stopped"
    item:set_finished()
  end)
end)
