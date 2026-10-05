local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_ice_rod")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

-- Event called when the hero is using this item.
item:register_event("on_using", function(self)
  if not item:try_spend_ammo(15) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  x = x + game:dx(24)[direction]
  y = y + game:dy(24)[direction]
  local projectile = map:create_fire{x=x, y=y, layer=z}
  local m = sol.movement.create"straight"
  m:set_angle(direction * math.pi/2)
  m:set_max_distance(250)
  m:set_speed(240)
  m:set_smooth(false)
  m:start(projectile)
  hero:set_animation("rod_swing", function()
    hero:set_animation"stopped"
    item:set_finished()
  end)
end)

