--[[
A note on how to set command bindings in 2.0+, putting it here because I'm not sure where else to:

If you want to set which stick is for axis movement, you have to use:
      sol.controls.get_main_controls():set_joypad_axis_binding("X", "left_x")
This "set_joypad_axis_binding" is for analog axis _movement_ - i.e., how you make the player walk -, from what I can tell
If you want to put any other command onto an axis (which includes the triggers), then you don't use "set_joypad_axis_binding",
you use "set_joypad_binding" as though it were a button, AND you must include a + or - to indicate the axis movemet direction. For example:
      sol.controls.get_main_controls():set_joypad_binding("aim", "trigger_left +")

--]]

return {
  joypad = {
    ["a"] = {"action", "confirm",},
    ["b"] = {"dodge", "cancel",},
    ["x"] = {"item_1"},
    ["y"] = {"item_2"},
    ["start"] = {"pause"},

    ["right_shoulder"] = {"attack", "submenu_right"},
    ["left_shoulder"] = {"submenu_left", },
    ["trigger_left +"] = {"aim"},
    ["trigger_right +"] = {"fire"},

    ["dpad_right"] = {"right", "quickswap_gun"},
    ["dpad_up"] = {"up", "quickswap_item_2"},
    ["dpad_left"] = {"left", "quickswap_melee"},
    ["dpad_down"] = {"down", "quickswap_item_1"},

    ["back"] = {"map"},

  },

  joypad_axis = {
    ["left_x"] = { "X +" },
    ["left_y"] = { "Y +" },
    ["right_x"] = { "aim_x +" },
    ["right_y"] = { "aim_y +" },
  },

  keyboard = {
    ["d"] = {"right"},
    ["w"] = {"up"},
    ["a"] = {"left"},
    ["s"] = {"down"},

    ["e"] = {"action", "confirm",},
    ["space"] = {"dodge", "confirm",},
    ["escape"] = {"pause"},
    ["tab"] = {"cancel"},
    ["backspace"] = {"cancel"},
    ["j"] = {"attack", "submenu_left", "wraithshot"},
    ["k"] = {"aim", "submenu_right"},
    ["l"] = {"fire", "hookshot"},
    ["q"] = {"item_2"},
    ["c"] = {"item_1"},
    ["f"] = {"weapon_art"},
    ["m"] = {"map"},

    ["1"] = {"quickswap_melee"},
    ["2"] = {"quickswap_gun"},
    ["3"] = {"quickswap_item_2"},
    ["4"] = {"quickswap_item_1"},
    --[""] = {""},
    --[""] = {""},
  },

  kbm = {
    ["d"] = {"right"},
    ["w"] = {"up"},
    ["a"] = {"left"},
    ["s"] = {"down"},

    ["e"] = {"action", "confirm",},
    ["space"] = {"dodge", "confirm",},
    ["escape"] = {"pause"},
    ["tab"] = {"cancel"},
    ["backspace"] = {"cancel"},
    ["q"] = {"item_2"},
    ["c"] = {"item_1"},

    ["f"] = {"attack", "fire", "submenu_left"},
    ["left shift"] = {"aim"},
    ["g"] = {"wraithshot", "hookshot", "submenu_right"},
    ["r"] = {"weapon_art"},
    ["m"] = {"map"},

    ["1"] = {"quickswap_melee"},
    ["2"] = {"quickswap_gun"},
    ["3"] = {"quickswap_item_2"},
    ["4"] = {"quickswap_item_1"},
  },

  keyboard_chris = {
    ["d"] = {"right"},
    ["w"] = {"up"},
    ["a"] = {"left"},
    ["s"] = {"down"},
    ["return"] = {"action", "confirm",},
    ["space"] = {"dodge", "confirm",},
    ["escape"] = {"cancel"},
    ["backspace"] = {"cancel"},
    ["j"] = {"attack"},
    ["k"] = {"aim"},
    ["l"] = {"fire"},
    ["n"] = {"item_2"},
    ["h"] = {"item_1"},
    ["`"] = {"pause"},

    ["u"] = {"quickswap_melee"},
    ["i"] = {"quickswap_gun"},
    ["o"] = {"quickswap_item_2"},
    ["p"] = {"quickswap_item_1"},
    --[""] = {""},
    --[""] = {""},
  },

}

