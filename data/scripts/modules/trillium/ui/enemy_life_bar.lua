--[[
Enemy life bar
By Max Mraz, licensed MIT
Usage:
- require this script (probably from features.lua)
- when an enemy gets hurt, call enemy:show_life_bar()
- The bar will last for like 10s, then fade away (timer is renewed whenever the enemy takes damage)
- NOTE: bar is only updated when you call enemy:show_life_bar(), since I assume you'll call it whenever the enemy is hurt
--]]


local bar_fade_out_delay = 7000
local bar_width, bar_height = 24, 2
local border_color = {220,210,175}
local background_color = {20,20,20}
local life_color = {180,0,0}
local bar_opacity = 180
local damage_number_opacity = 180
local damage_number_duration = 1000


local enemy_meta = sol.main.get_metatable("enemy")
local game_meta = sol.main.get_metatable("game")
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()


local builder = {}

function builder.new()
  local menu = {}

  local max_life = 100 --placeholder, will be updated
  local current_life = nil --placeholder, will be updated
  local border = sol.surface.create(bar_width + 2, bar_height + 2)
  border:fill_color(border_color)
  local background = sol.surface.create(bar_width, bar_height)
  background:fill_color(background_color)
  local health_surface = sol.surface.create(bar_width, bar_height)
  health_surface:fill_color(life_color)
  local bar_surface = sol.surface.create(bar_width + 2, bar_height + 2)
  bar_surface:set_opacity(bar_opacity)
  local damage_number_surface = sol.text_surface.create{
    horizontal_alignment = "right",
    vertical_alignment = "bottom",
    font = font, font_size = font_size,
    color = border_color,
  }
  damage_number_surface:set_opacity(damage_number_opacity)


  --This is the function that should be called to show and change the bar:
  function menu:set_life(amount)
    if not current_life then current_life = max_life end
    local damage_amount = current_life - amount
    current_life = amount
    --Update bar and show damage amount:
    if current_life <= 0 then
      sol.menu.stop(menu)
    else
      menu:update()
      menu:show_damage_amount(damage_amount)
      menu:restart_fade_out_timer()
    end
  end


  function menu:should_show()
    return (menu.host and menu.host:exists() and menu.host:is_visible() and menu.host:get_life() > 0 and menu.camera)
  end


  function menu:update()
    --health_surface:clear()
    local life_percent = current_life / max_life
    border:draw(bar_surface)
    background:draw(bar_surface, 1, 1)
    health_surface:draw_region(0, 0, bar_width * life_percent, bar_height, bar_surface, 1, 1)
  end


  function menu:on_draw(dst)
    if not menu:should_show() then return end
    local x, y = menu.host:get_position()
    local camx, camy = menu.camera:get_position()
    x = x - camx - bar_width / 2
    y = y - camy + menu.y_offset
    bar_surface:draw(dst, x, y)
    damage_number_surface:draw(dst, x + bar_width, y - 1)
  end


  function menu:set_max_life(amount)
    max_life = amount
  end


  function menu:set_host(entity)
    menu.host = entity
    menu.camera = entity:get_map():get_camera()
    local w, h = entity:get_sprite():get_size()
    menu.y_offset = h * -1 - 8
  end


  function menu:restart_fade_out_timer()
    if menu.fade_out_timer then
      menu.fade_out_timer:stop()
    end
    menu.fade_out_timer = sol.timer.start(menu, bar_fade_out_delay, function()
      menu:fade_out()
    end)
  end


  function menu:fade_out()
    sol.menu.stop(menu)
  end


  function menu:show_damage_amount(amount)
    amount = (menu.displayed_damage or 0) + amount
    menu.displayed_damage = amount
    damage_number_surface:set_text("")
    damage_number_surface:set_text(math.floor(amount))
    if menu.damage_number_timer then menu.damage_number_timer:stop() end
    menu.damage_number_timer = sol.timer.start(menu, damage_number_duration, function()
      menu.displayed_damage = 0
      damage_number_surface:set_text("")
    end)
  end


  return menu
end



function enemy_meta:show_life_bar()
  assert(self.max_life, "Cannot show life bar for an enemy that does not have an enemy.max_life value")
  if self.has_boss_bar then return end --don't show a bar if there's already a giant one at the bottom of the screen lol
  local enemy = self
  local bar
  if enemy.life_bar then
    bar = enemy.life_bar
  else
    bar = builder.new()
    bar:set_max_life(enemy.max_life)
    bar:set_host(enemy)
    enemy.life_bar = bar
  end
  if not sol.menu.is_started(bar) then
    sol.menu.start(enemy:get_map(), bar)
  end
  bar:set_life(enemy:get_life())

end
