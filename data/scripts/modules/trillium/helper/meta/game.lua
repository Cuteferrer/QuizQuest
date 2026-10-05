sol.modules.get_object("multi_events")

local game_meta = sol.main.get_metatable"game"

function game_meta:dx(offset)
  return {[0] = offset, [1] = 0, [2] = offset * -1, [3] = 0}
end

function game_meta:dy(offset)
  return {[0] = 0, [1] = offset * -1, [2] = 0, [3] = offset}
end

function game_meta:get_direction_held()
  local game = self
  local hero = game:get_hero()
  local up = game:is_command_pressed("up")
  local right = game:is_command_pressed("right")
  local left = game:is_command_pressed("left")
  local down = game:is_command_pressed("down")
  local direction = hero:get_direction() * 2
  if up and right then direction = 1
  elseif up and left then direction = 3
  elseif down and left then direction = 5
  elseif down and right then direction = 7
  elseif up then direction = 2
  elseif left then direction = 4
  elseif down then direction = 6
  elseif right then direction = 0
  end
  return direction
end

--Track playtime:
local time_save_var = "total_playtime"
function game_meta:track_playtime()
  local game = self
  local playtime = game:get_value(time_save_var) or 0
  sol.timer.start(game, 1000, function()
    playtime = playtime + 1
    game:set_value(time_save_var, playtime)
    return true
  end)
end

function game_meta:get_playtime()
  return self:get_value(time_save_var)
end

game_meta:register_event("on_started", function(game)
  game:track_playtime()
end)



return game_meta
