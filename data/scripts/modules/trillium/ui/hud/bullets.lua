local builder = {}

local bullet_limit = 24 --the most bullets you could ever possibly have
local max_width = bullet_limit * 8

function builder:new(game, config)
  local menu = {}
  menu.surface = sol.surface.create(max_width, 16)
  menu.x, menu.y = config.x, config.y

  local bullet_sprites = {}
  local animation_bullet = sol.sprite.create("hud/bullet")
  animation_bullet:set_animation"invisible"
  animation_bullet.x_offset = 0

  function draw_bullets()
    menu.surface:clear()
    for i, sprite in ipairs(bullet_sprites) do
      sprite:draw(menu.surface, sprite.x_offset, 13)
    end
  end

  function menu:rebuild()
    local max_bullets = game:get_max_bullets()
    local current_bullets = game:get_bullets()

    for i = 1, max_bullets do
      local sprite = sol.sprite.create("hud/bullet")
      sprite.x_offset = 4 + 6 * i
      if i <= current_bullets then
        sprite:set_animation"full"
      else
        sprite:set_animation"empty"
      end
      bullet_sprites[i] = sprite
    end
    menu.displayed_bullets = current_bullets
    menu.displayed_bullets_max = max_bullets
    draw_bullets()
  end


  function menu:add_bullet()
    local sprite = bullet_sprites[menu.displayed_bullets + 1]
    sprite:set_animation("full")
    draw_bullets()
    menu.displayed_bullets = menu.displayed_bullets + 1
    sol.audio.play_sound"bullet_fill"
    animation_bullet:set_animation("reloading")
    animation_bullet.x_offset = sprite.x_offset
  end


  function menu:on_draw(dst)
    menu.surface:draw(dst, menu.x, menu.y)
    animation_bullet:draw(dst, animation_bullet.x_offset + menu.x, 13 + menu.y)
  end

  menu:rebuild()

  --Check for rebuilding:
  sol.timer.start(game, 150, function()
    local current_bullets = game:get_bullets()
    if menu.displayed_bullets_max ~= game:get_max_bullets() then
      menu:rebuild()
    elseif menu.displayed_bullets < current_bullets then
      menu:add_bullet()
    elseif menu.displayed_bullets > current_bullets then
      menu:rebuild()
    end
    return true
  end)

  return menu
end

return builder