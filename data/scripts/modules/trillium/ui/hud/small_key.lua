--[[
By Max Mraz, licensed MIT
Displays an icon for each small key you have when you're on certain maps
This script must be required, probably from features.lua

map_key_map is a table where each entry's key is the map ID of a map, and the value is the name of its small key item.
So for instance if you're on the map "doom_mountain/fire_temple", and the keys you get there are the item "keys/fire_temple_small_key", then you'd have:
map_key_map["doom_mountain/fire_temple"] = "keys/fire_temple_small_key"

--]]

local small_key_menu = {x = 8, y = 200} --set where you want to draw here

local map_key_map = {}
  map_key_map["example_map/example_dungeon"] = "keys/example_small_key"

local key_sprite = sol.sprite.create("hud/small_key_icon") --set which sprite you want displayed
local sprite_width, sprite_height = 12, 16 --set size of the sprite since they'll be drawn next to each other

local key_surface = sol.surface.create()

local key_item

local map_meta = sol.main.get_metatable"map"

map_meta:register_event("on_started", function(self)
	local map = self
  local game = map:get_game()
  key_item = map_key_map[map:get_id()] or nil
  if key_item and not sol.menu.is_started(small_key_menu) then
    sol.menu.start(game, small_key_menu)
  elseif sol.menu.is_started(small_key_menu) then
    sol.menu.stop(small_key_menu)
  end
end)

function small_key_menu:on_started()
  --update number of keys every 200ms or so
  small_key_menu:update_keys()
  sol.timer.start(sol.main.get_game():get_map(), 200, function() small_key_menu:update_keys() return true end)
end

function small_key_menu:update_keys()
  local game = sol.main.get_game()
  local key_amount = game:get_item(key_item):get_amount()
  key_surface:clear()
  for i = 1, key_amount do
    key_sprite:draw(key_surface, (i * sprite_width), sprite_height - 3)
  end
end

function small_key_menu:on_draw(dst)
  key_surface:draw(dst, small_key_menu.x, small_key_menu.y)
end


return small_key_menu