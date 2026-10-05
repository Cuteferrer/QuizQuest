local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  local sprite = entity:get_sprite()
  sprite:set_animation("empty") --the "deault" sprite has the tumbleweed drawn just for map placement reasons
  entity:create_tumbleweed(true)
end


function entity:create_tumbleweed(skip_animation)
  local x, y, z = entity:get_position()
  local tumbleweed = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = "hazards/tumbleweed",
    model = "hazards/tumbleweed",
  }
  local sprite = tumbleweed:get_sprite()
  if not skip_animation then
    sprite:set_animation("growing", function()
      sprite:set_animation("stopped")
    end)
  end
  if entity:get_property("anchored") == "true" then
    tumbleweed.anchored = true
  end

  sol.timer.start(entity, 2000, function()
    if entity:overlaps(tumbleweed) and tumbleweed:exists() then
      return true
    else
      --Create tumbleweed after a pause
      sol.timer.start(entity, 8000, function()
        entity:create_tumbleweed()
      end)
    end
  end)
end
