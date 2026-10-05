return {
  joypad = {
    ["a"] = {"action", "confirm",},
    ["b"] = {"dodge", "cancel",},
    ["x"] = {"item_1"},
    ["y"] = {"item_2"},
    ["start"] = {"pause"},

    ["right_shoulder"] = {"attack", "submenu_right", "wraithshot",},
    ["left_shoulder"] = {"weapon_art", "submenu_left", },
    ["trigger_left +"] = {"aim"},
    ["trigger_right +"] = {"fire", "hookshot"},

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

  --Solarus defaults:
  keyboard = {
    ["right"] = {"right"},
    ["up"] = {"up"},
    ["left"] = {"left"},
    ["down"] = {"down"},
    ["return"] = {"action", "confirm",},
    ["space"] = {"dodge", "confirm",},
    ["escape"] = {"cancel"},
    ["backspace"] = {"cancel"},
    ["c"] = {"attack", "wraithshot"},
    ["left shift"] = {"aim", "submenu_left"},
    ["right shift"] = {"aim", "submenu_right"},
    ["z"] = {"fire", "hookshot"},
    ["x"] = {"item_2"},
    ["v"] = {"item_1"},
    ["d"] = {"pause"},
    ["f"] = {"weapon_art"},

    ["1"] = {"quickswap_melee"},
    ["2"] = {"quickswap_gun"},
    ["3"] = {"quickswap_item_2"},
    ["4"] = {"quickswap_item_1"},
    --[""] = {""},
    --[""] = {""},
  },

  kbm = {
    ["right"] = {"right"},
    ["up"] = {"up"},
    ["left"] = {"left"},
    ["down"] = {"down"},
    ["return"] = {"action", "confirm",},
    ["space"] = {"dodge", "confirm",},
    ["escape"] = {"cancel"},
    ["backspace"] = {"cancel"},
    ["c"] = {"attack", "wraithshot"},
    ["left shift"] = {"aim", "submenu_left"},
    ["right shift"] = {"aim", "submenu_right"},
    ["z"] = {"fire", "hookshot"},
    ["x"] = {"item_2"},
    ["v"] = {"item_1"},
    ["d"] = {"pause"},
    ["f"] = {"weapon_art"},

    ["1"] = {"quickswap_melee"},
    ["2"] = {"quickswap_gun"},
    ["3"] = {"quickswap_item_2"},
    ["4"] = {"quickswap_item_1"},
  },
}

