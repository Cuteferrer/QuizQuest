local item = ...
local game = item:get_game()

local heal_amount = 8
local magic_cost = 100
local tree_lifetime = 8000
local heal_frequency = 700
local heal_range = 32

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
  hero:set_animation("casting")
  local x, y, z = hero:get_position()
  portal_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  portal_entity:get_sprite():set_animation"summoning_portal"
  portal_entity:get_sprite():set_color_modulation{150,255,150}
  --[[light_effect_entity = map:create_custom_entity{
    x=x, y=y+4, layer=z, direction=0, width=16, height=16, sprite = "entities/lantern_sparkle",
  }
  light_effect_entity:set_drawn_in_y_order(true)
  light_effect_entity:get_sprite():set_animation"summoning_circle"
  light_effect_entity:get_sprite():set_color_modulation{150,255,150}--]]

  sol.timer.start(map, 1000, function()
    portal_entity:remove()
    hero:unfreeze()
    local tree = map:create_custom_entity{
      x = x + game:dx(24)[direction],
      y = y + game:dy(24)[direction],
      layer = z,
      width = 16, height = 16, direction = 0,
      sprite = "items/mending_tree"
    }
    tree:set_drawn_in_y_order()
    local tree_sprite = tree:get_sprite()
    tree_sprite:set_opacity(150)
    tree_sprite:set_animation("growing", function()
      tree_sprite:set_animation"glowing"
    end)
    sol.timer.start(tree, tree_lifetime, function()
      tree_sprite:fade_out()
      sol.timer.start(tree, 1000, function() tree:remove() end)
    end)
    sol.timer.start(tree, heal_frequency, function()
      if tree:get_distance(hero) <= heal_range then
        game:add_life(1)
      end
      if tree:exists() then return true end
    end)
  end)
end)


