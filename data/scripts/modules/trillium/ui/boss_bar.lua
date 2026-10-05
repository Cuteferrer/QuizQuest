--[[
Boss life bar
By Max Mraz and Jake Wagner, licensed MIT
Usage:
- require this script
- any enemy you want to be the boss, call enemy:start_boss_bar()

NOTES:
- All enemies using this must have a string name at "enemies.enemy_breed"
--]]

local enemy_meta = sol.main.get_metatable("enemy")
local game_meta = sol.main.get_metatable("game")
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()
local screen_w, screen_h = sol.video.get_quest_size()
local damage_number_duration = 1000

local builder = {}
builder.bars = {}

--To give any enemy the method to start a boss bar, we'll add a function to the enemy metatable
--NOTE: in order for the progam to know we're writing to the enemy metatable, we need to run this script. We'll do that by requiring it from scripts/features
function enemy_meta:start_boss_bar()
  local menu = builder:new()
  if not sol.menu.is_started(menu) then
    sol.menu.start(self:get_map(), menu)
  end
  menu:set_enemy(self)
  --mark enemy as a boss:
  self.has_boss_bar = true --I don't give a way to un-set this because presumably the bar lasts until they die --UPDATE: well the day came
  self.boss_bar = menu
end

function enemy_meta:stop_boss_bar()
  if self.boss_bar then
    sol.menu.stop(self.boss_bar)
  end
end


--For convenience, we assume all boss battles will have this boss health bar.
--Therefore, we might change the behavior of some items or menus depending on if you're in a boss fight, and provide this function to check
function game_meta:is_boss_battle_active()
  local is_active = false
  for i, bar in pairs(builder.bars) do
    if sol.menu.is_started(bar) then
      is_active = true
      break
    end
  end
  return is_active
end


function builder:new()
  --First, let's sort out if there's any other active boss bars:
  local sorted_bars = {}
  for i, bar_menu in ipairs(builder.bars) do
    if sol.menu.is_started(bar_menu) then
      --Make sure a corresponding enemy exists if there's a boss bar for it:
      if (not bar_menu.enemy) or (not bar_menu.enemy:exists()) or (bar_menu.enemy:get_life() <= 0) then
        sol.menu.stop(bar_menu)
      else
        sorted_bars[#sorted_bars + 1] = bar_menu
      end
    end
  end
  builder.bars = sorted_bars

  local menu = {}
  local bar_no = #builder.bars + 1

  --Config:
  local x_origin = 64
  local y_origin = 208
  local bar_height = 24 --if multiple boss bars are shown at once, offset them by how much:

  --Create all the necessary drawables
  menu.bar_background = sol.sprite.create"hud/stat_bars/boss_bar"
  menu.bar_background:set_animation("background")
  menu.health_bar = sol.sprite.create"hud/stat_bars/red"
  menu.bar_overlay = sol.sprite.create"hud/stat_bars/boss_bar"
  menu.bar_overlay:set_animation("overlay")
  menu.name_surface = sol.text_surface.create{
    font = font,
    font_size = font_size,
    horizontal_alignment = "center",
  }
  menu.damage_number_surface = sol.text_surface.create{
    font = font,
    font_size = font_size,
    horizontal_alignment = "right",
  }
  menu.displayed_damage = 0
  menu.width, menu.height = menu.bar_overlay:get_size()
  menu.bar_surface = sol.surface.create(menu.width, menu.height)





  --Applies the enemy's life to the percentage of the bar shown, adds enemy breed's name to boss bar
  function menu:set_enemy(enemy)
    menu.enemy = enemy
    menu.max_life = enemy.max_life or enemy:get_life()
    menu.displayed_life = menu.max_life
    enemy:register_event("on_hurt", function()
      menu:update_life()
    end)
    enemy:register_event("on_dying", function()
      if sol.menu.is_started(menu) then sol.menu.stop(menu) end
    end)
    --[[ Use this code instead if your enemies don't trigger an "on_hurt" (for example, weird environmental/puzzle actions remove their health and don't trigger the event)
    sol.timer.start(enemy:get_map(), 100, function()
      menu:update_life()
      return true
    end)
    --]]
    --Set name on boss bar
    menu.name_key = sol.language.get_string("enemies." .. enemy:get_breed():gsub("/", "."))
    menu.name_surface:set_text(menu.name_key)
    menu:update_life() --manually call at the beginning to get everything drawn on screen
  end


  function menu:update_life()
    local current_life = math.floor(menu.enemy:get_life())
    if current_life <= 0 and sol.menu.is_started(menu) then
      sol.menu.stop(menu)
      return
    end
    --Damage number:
    local damage_amount = math.floor(menu.displayed_life - current_life)
    if damage_amount > 0 then
      menu:show_damage_amount(damage_amount)
    end
    --Update values:
    menu.displayed_life = current_life
    --Draw Bar:
    local health_width = menu.width * current_life / menu.max_life
    menu.bar_surface:clear()
    menu.bar_background:draw(menu.bar_surface, 0, 16)
    menu.health_bar:draw_region(0, 0, health_width, menu.height, menu.bar_surface, 0, 17)
    menu.bar_overlay:draw(menu.bar_surface, 0, 0)
    menu.name_surface:draw(menu.bar_surface, menu.width / 2, 6)
  end


  function menu:show_damage_amount(amount)
    if not sol.menu.is_started(menu) then return end --idk how this is getting called after the menu is stopped, but it is
    if menu.damage_number_timer then menu.damage_number_timer:stop() end
    local init_damage = menu.displayed_damage or 0
    menu.displayed_damage = init_damage + amount
    menu.damage_number_surface:set_text(menu.displayed_damage)
    menu.damage_number_timer = sol.timer.start(menu, damage_number_duration, function()
      menu.displayed_damage = 0
      menu.damage_number_surface:set_text("")
    end)
  end


  function menu:on_draw(dst)
    local y = y_origin - (bar_no - 1) * bar_height
    menu.bar_surface:draw(dst, x_origin, y)
    menu.damage_number_surface:draw(dst, x_origin + menu.width - 16, y + 6)
  end

  builder.bars[bar_no] = menu

  return menu

end


