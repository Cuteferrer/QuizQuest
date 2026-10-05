local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  sol.timer.start(entity, math.random(500, 9000), function()
    local hero = map:get_hero()
    if (entity:get_distance(hero) < 400) and entity:is_in_same_region(hero) then
      entity:drip()
    end
    return math.random(6000, 9000)
  end)

end


function entity:drip()
  local sprite = entity:create_sprite("effects/ripple")
  sprite:set_animation("ripple", function()
    entity:remove_sprite(sprite)
  end)
  sol.audio.play_sound("ambiance/cave_drip_0" .. math.random(1, 3))
end
