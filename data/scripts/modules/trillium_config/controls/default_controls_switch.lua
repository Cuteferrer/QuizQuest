return {
  joypad = {
    --Remember, as far as Solarus knows, the bottom button is A and the right button is B:
    --The Switch Icons show in reverse, where the "b" button shows an "A" icon, so this is correct:
    ["b"] = {"action", "confirm",},
    ["a"] = {"dodge", "cancel",},
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

  keyboard = {},

  kbm = {},

}

