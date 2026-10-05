--[[
Created by Max Mraz, licensed MIT
A component where a button must be held to trigger a callback


--]]

local factory = {}


function factory.create(conf)
  assert(conf, "Need to pass a config object to hold_to_confirm menu factory")
  local font, font_size, line_height = sol.modules.get_object("language_manager"):get_menu_font()
  local menu = {}

  --defaults
  menu.input_command = conf.input_command or "confirm"
  menu.callback = conf.callback or function() end
  menu.hold_duration = conf.hold_duration or 2000
  if conf.text_string then
    menu.text = sol.language.get_string(conf.text_string)
  else
    menu.text = ""
  end
  menu.hidden = conf.hidden or false --will only show up once you press the input command button
  menu.position = conf.position or {x=0, y=0}
  local loader_padding = 4

  --init
  menu.time_held = 0
  menu.text_surface = sol.text_surface.create{
    font=font, font_size=font_size, vertical_alignment = "top",
    text = menu.text
  }
  local txw, txh = menu.text_surface:get_size()
  local loader_w, loader_h = txw + loader_padding * 2, txh + loader_padding * 2
  local loader_bg = sol.surface.create(loader_w, loader_h)
  loader_bg:fill_color{255,255,255}
  loader_bg:set_opacity(50)
  local loader_fg = sol.surface.create(loader_w, loader_h)
  loader_fg:fill_color{255,255,255}
  loader_fg:set_opacity(180)
  menu.loader_surface = sol.surface.create(loader_w, loader_h)
  if menu.hidden then menu.loader_surface:set_opacity(0) end

  function menu:set_input_command(cmd)
    menu.input_command = cmd
  end

  function menu:update_loader()
    menu.loader_surface:clear()
    loader_bg:draw(menu.loader_surface, 0, 0)
    loader_fg:draw_region(0, 0, (menu.time_held / menu.hold_duration) * loader_w, loader_h, menu.loader_surface, 0, 0)
    menu.text_surface:draw(menu.loader_surface, loader_padding, loader_padding)
  end


  function menu:on_draw(dst)
    menu:update_loader()
    menu.loader_surface:draw(dst, menu.position.x, menu.position.y)
  end


  function menu:on_command_pressed(command)
    local handled = false
    if command == menu.input_command then
      menu:start_holding()
      if menu.hidden then menu.loader_surface:fade_in() end
      handled = true
    end
    return handled
  end


  function menu:on_command_released(command)
    local handled = false
    if command == menu.input_command then
      menu:stop_holding()
      if menu.hidden then menu.loader_surface:fade_out() end
    end
    return handled
  end



  function menu:start_holding()
    local step = 10
    menu.time_held = 0
    menu.hold_timer = sol.timer.start(menu, step, function()
      menu.time_held = menu.time_held + step
      if menu.time_held >= menu.hold_duration then
        menu.callback()
      else
        return true
      end
    end)
  end


  function menu:stop_holding()
    if menu.hold_timer then
      menu.hold_timer:stop()
    end
    menu.hold_timer = nil
    menu.time_held = 0
  end



  return menu
end


return factory

