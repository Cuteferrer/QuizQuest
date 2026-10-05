local item = ...
local game = item:get_game()
local bomb_speed = 140
local bomb_max_distance = 240

item:register_event("on_created", function(self)
  item:set_savegame_variable("possession_clockwork_bombs_counter")
  item:set_amount_savegame_variable("amount_clockwork_bombs_counter")
  item:set_assignable(true)
  item:set_amount_savegame_variable("amount_clockwork_bombs_counter")
  item:set_max_amount(999)
  item:set_amount(20)
  item:set_ammo("_amount")
end)


item:register_event("on_using", function(self)
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
  local direction = hero:get_direction()
  local bomb = map:create_custom_entity{
    width=16, height=16, direction=direction,
    layer = z,
    x = x + game:dx(16)[direction],
    y = y + game:dy(16)[direction],
    sprite = "entities/clockwork_bomb",
  }
  bomb:set_can_traverse("enemy", false)
  local m = sol.movement.create"straight"
  m:set_angle(direction * math.pi / 2)
  m:set_speed(bomb_speed)
  m:set_max_distance(bomb_max_distance)
  m:start(bomb, function()
    item:explode(bomb)
  end)
  function m:on_obstacle_reached()
    item:explode(bomb)
  end
end


function item:explode(bomb)
  local map = bomb:get_map()
  local x, y, z = bomb:get_position()
  bomb:remove()
  map:create_explosion{x=x, y=y, layer=z}
  sol.audio.play_sound"explosion"
end
