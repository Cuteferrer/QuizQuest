local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local freq_min, freq_max = 2000, 5000

function entity:on_created()
  local sprite = entity:get_sprite()
  sprite:set_opacity(0)
  sol.timer.start(entity, math.random(10, freq_min + freq_min / 2), function()
    sprite:set_opacity(200)
    sprite:set_animation("shimmer")
    return math.random(freq_min, freq_max)
  end)
end
