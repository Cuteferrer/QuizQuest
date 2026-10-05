--By Max Mraz, licensed MIT
--Status effect HUD elements, designed to work with Trillium status effects
--Shows up to MAX_EFFECTS_DISPLAYED of statuses returned from game:get_status_effects()
--Effect sprites must be located at sprites/hud/status_effects, with the name of each effect.type

local builder = {}
local MAX_EFFECTS_DISPLAYED = 7
local icons = {}
for i = 1, MAX_EFFECTS_DISPLAYED do
  icons[i] = sol.sprite.create"hud/status_effects"
end

function builder:new(game, config)
  local menu = {}
  local hero = game:get_hero()

  menu.effects_surface = sol.surface.create(16, 240)
  menu.dst_x = config.x
  menu.dst_y = config.y

  local function draw_status_effects()
    local i = 1
    for _, effect in pairs(hero:get_status_effects()) do
      icons[i]:set_animation(effect.type)
      icons[i]:draw(menu.effects_surface, 8, 13 + i * 18)
      i = i + 1
      if i > MAX_EFFECTS_DISPLAYED then
        break
      end
    end
    for _, immunity in pairs(hero:get_status_immunities()) do
      local animation_name = immunity.type .. "_immunity"
      icons[i]:set_animation(animation_name)
      icons[i]:draw(menu.effects_surface, 8, 13 + i * 18)
      i = i + 1
      if i > MAX_EFFECTS_DISPLAYED then break end
    end
  end

  function menu:rebuild()
    menu.effects_surface:clear()
    draw_status_effects()
  end


  function menu:on_started()
    sol.timer.start(menu, 0, function()
      menu:rebuild()
      return 100
    end)
  end


  function menu:on_draw(dst_surface)
    local x, y = menu.dst_x, menu.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end
    menu.effects_surface:draw(dst_surface, x, y)
  end


  return menu
end

return builder