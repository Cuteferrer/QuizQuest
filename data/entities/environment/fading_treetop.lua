local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite

local TARGET_OPACITY = 100

function entity:on_created()
  entity:set_drawn_in_y_order()
  sprite = entity:get_sprite()
  sol.timer.start(entity, 200, function()
    local x, y, z = hero:get_position()
    local overlaps = entity:overlaps(x - 8, y - 13, 16, 16)
    if overlaps and not entity.transparent then
      entity.transparent = true
      entity:fade(-1)
    elseif not overlaps and entity.transparent then
      entity.transparent = false
      entity:fade(1)
    end
    return true
  end)
end

function entity:fade(step)
  sol.timer.start(10, function()
    local opacity = sprite:get_opacity()
    if (step == -1) and opacity > TARGET_OPACITY then
      sprite:set_opacity(opacity - 10)
      return true
    elseif step == 1 and opacity < 255 then
      sprite:set_opacity(opacity + 10)
      return true
    end
  end)
end
