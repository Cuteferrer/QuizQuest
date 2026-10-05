local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  entity.drillspear_boost = true
  local width, height = entity:get_size()
  entity.time_to_melt = 1000 * (width / 16 + height / 16)
end

function entity:react_to_hookshot()
  entity:shatter()
end

function entity:react_to_drillspear()
  entity:shatter()
end

function entity:react_to_fire(fire)
  if not entity:exists() then return end
  sol.timer.start(self, entity.time_to_melt, function()
    if fire:exists() then
      entity:melt()
    end
  end)
end

function entity:shatter()
  if entity.shattered then return end
  entity.shattered = true
  entity:get_sprite():set_animation("breaking", function()
    entity:remove()
  end)
end

function entity:melt()
  local sprite = entity:get_sprite()
  local size = 100
  sol.timer.start(entity, 40, function()
    if size >= 5 then
      size = size - 10
      sprite:set_scale(1, size / 100)
      return true
    else
      entity:remove()
    end
  end)
end
