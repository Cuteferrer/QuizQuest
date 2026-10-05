--NOTE:
--I don't think this is used anywhere?
--TODO: delete this????


--[[
Returns a list of all commands.
Add custom commands here - but you probably want to make sure they're accounted for in your defaults as well.

Note: the reason for having this list, as well as the list of defaults, is because it's possible that you might not bind every custom command for both keyboard and joypad.
For example, perhaps you bind shortcuts to the map, inventory, and quest log to number keys on the keyboard for convenience. However, players on controller will need to navigate the menu manually to reach these screens.
--]]




return {
  --Engine Commands:
  "right", "up", "left", "down",
  "action", "attack", "item_1", "item_2", "pause",

  --Custom Commands:
  "aim", "dodge", "fire", "wraithshot", "weapon_art", "hookshot",
  "quickswap_melee", "quickswap_gun", "quickswap_item_1", "quickswap_item_2",
  "map",

}
