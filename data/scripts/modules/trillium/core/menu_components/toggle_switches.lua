local manager = {}


function manager.apply_behavior(menu)
  --Apply some settings for any toggleable objects in the grid:
  for _, ob in pairs(menu.allowed_objects) do
    if ob.toggleable then
      ob.sprite = "menus/ui/toggle_switch"
      ob.sprite_offset = ob.sprite_offset or {x = menu.cell_width - 18, y = 10}
      ob.activation_function = ob.activation_function or function() return false end

      function ob:toggle()
        ob.activated = not ob.activated
        ob.animation = (ob.activated and "on" or "off")
        sol.audio.play_sound("cursor")
        menu:update_objects()
      end
    end
  end


  function menu:set_toggles()
    for _, ob in pairs(menu.allowed_objects) do
      if ob.toggleable then
        ob.activated = ob.activation_function()
        --Set toggle sprite accordingly:
        ob.animation = ob.activated and "on" or "off"
        menu:update_objects()
      end
    end
  end


  menu:register_event("on_started", function()
    menu:set_toggles()
  end)
end


return manager
