-- Defines the elements to put in the HUD
-- and their position on the game screen.
-- Negative x or y coordinates mean to measure from the right or bottom
-- of the screen, respectively.

local tlx, tly = 8, 0
local item_x, item_y = 4, 188
local item_radius = 14
local screen_w, screen_h = sol.video.get_quest_size()
local bullet_offset_x, bullet_offset_y = 18, 6

local hud_script_prefix = "scripts/modules/trillium/ui/hud/"

local hud_config = {

  -- Health
  {
    menu_script = hud_script_prefix .. "hearts",
    x = tlx,
    y = tly + 12,
  },

  --Magic:
  {
    menu_script = hud_script_prefix .. "bar_magic",
    x = tlx,
    y = tly,
  },

  --Effect icons
  {
    menu_script = hud_script_prefix .. "effect_icon_queue",
    x = tlx + 32,
    y = tly - 10,
  },

  --Status buildup bars:
  {
    menu_script = hud_script_prefix .. "status_bar_queue",
    --x = tlx - 28, y = tly + 46,
    x = screen_w / 2 - 25, y = screen_h - 56
  },

  -- Money counter.
  {
    menu_script = hud_script_prefix .. "money",
    x = -56,
    y = 208,
  },

  -- Equipped Items:
  --Melee
  {
    menu_script = hud_script_prefix .. "item",
    x = item_x + item_radius * 2,
    y = item_y + item_radius,
    slot = "melee",
  },
 -- Item 1
  {
    menu_script = hud_script_prefix .. "item",
    x = item_x,
    y = item_y + item_radius,
    slot = 1,
  },
  --Item 2
  {
    menu_script = hud_script_prefix .. "item",
    x = item_x + item_radius,
    y = item_y,
    slot = 2,
  },


 -- Items picked-up (used when buying item in shops as well)
  {
    menu_script = hud_script_prefix .. "item_panel_queue",
    x = -48,
    y = 16,
    duration = 2500,
  },

  --Interaction Icon
  {
    menu_script = hud_script_prefix .. "interact_icon",
    --x = 4, y = 222,
    x = 4, y = 156,
  },

  --Status effect icons
  --[[
  {
    menu_script = hud_script_prefix .. "status_effects",
    x = 2, y = 20,
  },
  --]]

  --Message Queue
  {
    menu_script = hud_script_prefix .. "message_queue",
  },
}

return hud_config
