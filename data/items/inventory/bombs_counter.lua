local item = ...
local game = item:get_game()

item:register_event("on_created", function(self)
  item:set_savegame_variable("possession_bomb_counter")
  item:set_assignable(true)
  item:set_amount_savegame_variable("amount_bomb_counter")
  item:set_max_amount(999)
  item:set_amount(30)
  item:set_ammo("_amount")
end)


item:register_event("on_using", function()
  if item:try_spend_ammo() then
    local x, y, layer = item:summon_bomb()
    sol.audio.play_sound("bomb")
    item:set_finished()
  else
    item:set_finished()
  end
end)

function item:summon_bomb()
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()
  local dx = {[0]=16, [1]= 0, [2]=-16, [3]=0}
  local dy = {[0]=0, [1]=-16, [2]=0, [3]=16}
  local bomb = map:create_custom_entity{
    width=16, height=16, direction=0,
    layer = z,
    x = x + dx[hero:get_direction()],
    y = y + dy[hero:get_direction()],
    model = "hero_projectiles/custom_bomb",
--sprite = "entities/bomb",
  }
  sol.timer.start(game, 10, function()
    game:simulate_command_pressed("action")
    sol.timer.start(game, 10, function() game:simulate_command_released("action") end)
  end)
end
