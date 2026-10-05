local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spark_spell")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(10) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  x = x + game:dx(28)[direction]
  y = y + game:dy(28)[direction]
  local zap = map:create_lightning{x=x, y=y, layer=z, type="lightning_zap"}

  item:set_finished()
end)

