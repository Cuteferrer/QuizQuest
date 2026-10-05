--Main keyboard context
local main_controls = sol.controls.get_main_controls()
sol.main:register_event("on_key_pressed", function(self, key, modifiers)
  local handled = false
  if key == "f11" or
    (key == "return" and (modifiers.alt or modifiers.control)) then
    -- F11 or Ctrl + return or Alt + Return: switch fullscreen.
    sol.video.set_fullscreen(not sol.video.is_fullscreen())
    sol.video.set_cursor_visible(not sol.video.is_fullscreen())
    handled = true
  elseif key == "f4" and modifiers.alt then
    -- Alt + F4: stop the program.
    sol.main.exit()
    handled = true

  --Hard Code arrow keys to corresponding commands
  --We don't double bind them, because then menus wouldn't know whether to show D or -> for Right
  elseif key == "up" then main_controls:simulate_pressed("up") handled = true
  elseif key == "down" then main_controls:simulate_pressed("down") handled = true
  elseif key == "left" then main_controls:simulate_pressed("left") handled = true
  elseif key == "right" then main_controls:simulate_pressed("right") handled = true

  end

  return handled
end)

sol.main:register_event("on_key_released", function(self, key)
  if key == "placeholder" then --nothng, just a pain to do "if" for the first arrow key, then "elseif" for the rest when copy/pasting

  elseif key == "up" then main_controls:simulate_released("up") handled = true
  elseif key == "down" then main_controls:simulate_released("down") handled = true
  elseif key == "left" then main_controls:simulate_released("left") handled = true
  elseif key == "right" then main_controls:simulate_released("right") handled = true

  end
end)

