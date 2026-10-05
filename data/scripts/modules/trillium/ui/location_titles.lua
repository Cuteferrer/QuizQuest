--[[
By Max Mraz, licensed MIT

Show a big location title when you call the function.
Repeat visits to the same location will show a smaller version of the title in the corner of the screen.

Usage:
map:show_location_title(location_id, force_small)
- location_id (string, optional): ID to pull location name from. If not provided, it'll be looked up in config/world_data/location_title_map_lookup using the map's ID
- force_small (boolean, optional): if true, will show the title small and in the corner, rather than center screen, even on a first visit. I like this for minor locations. The big title slam loses power if overused.
--]]

local manager = {}
local menu = {}

local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"
local screen_width, screen_height = sol.video.get_quest_size()

local map_id_lookup = require("scripts/modules/trillium_config/world_data/location_title_map_lookup")


--[[
local title_font = "OldWood"
local little_font_size = 48
local big_font_size = 72
--]]

local savegame_prefix = "location_visited_"
local title_font = "ThestralNeue"
local little_font_size = 24
local big_font_size = 64
local font_shrink_amount = 24



menu.title_surface = sol.text_surface.create{
  font = title_font,
  font_size = little_font_size,
  vertical_alignment = "bottom",
  horizontal_alignment = "right",
  rendering_mode = "antialiasing",
}
menu.title_surface_line_2 = sol.text_surface.create{
  font = title_font,
  font_size = little_font_size,
  vertical_alignment = "bottom",
  horizontal_alignment = "right",
  rendering_mode = "antialiasing",
}
menu.big_title_surface = sol.text_surface.create{
  font = title_font,
  font_size = big_font_size,
  vertical_alignment = "middle",
  horizontal_alignment = "center",
  rendering_mode = "antialiasing",
}
menu.big_title_surface_line_2 = sol.text_surface.create{
  font = title_font,
  font_size = big_font_size,
  vertical_alignment = "middle",
  horizontal_alignment = "center",
  rendering_mode = "antialiasing",
}



function map_meta:show_location_title(location_id, force_small)
  local map = self
  local game = map:get_game()
  local map_id = map:get_id()
  --if location ID not explicitly passed, look it up in config table:
  if (location_id == "true") or (not location_id) then
    for prefix, id in pairs(map_id_lookup) do
      if map_id:match(prefix) then location_id = id break end
    end
  end
  if force_small then game:set_value(savegame_prefix .. location_id, true) end
  --Don't show the title if it's the same as the last one we showed:
  if menu.last_location == location_id then return end
  if map:get_game():get_last_displayed_location() == location_id then return end

  menu:set_title(location_id)
  sol.menu.start(game, menu)
  sol.timer.start(game, 3000, function()
    sol.menu.stop(menu)
  end)

  --Side effect:
  --If there is a world map landmark tied to the location title, unlock it:
  game:add_world_map_landmark("overworld", location_id)
end


function game_meta:reset_location_titles()
  local game = self
  --Won't reset titles triggered by custom , but will reset all those locations listed in the config
  for _, location_id in pairs(map_id_lookup) do
    game:set_value(savegame_prefix .. location_id, nil)
  end
end


function game_meta:has_visited_location(location_id)
  return self:get_value(savegame_prefix .. location_id)
end

function game_meta:set_visited_location(location_id, visited)
  if visited == nil then visited = true end
  return self:set_value(savegame_prefix .. location_id, visited)
end

function game_meta:unlock_all_locations()
  for _, id in pairs(map_id_lookup) do
    self:set_visited_location(id, true)
  end
end

function game_meta:get_last_displayed_location()
  return self:get_value("last_displayed_location_title")
end

function game_meta:set_last_displayed_location(loc_id)
  self:set_value("last_displayed_location_title", loc_id)
end



function menu:set_title(location_id)
  local game = sol.main.get_game()
  local location_string = sol.language.get_string("locations." .. location_id)
  assert(location_string, "No string found for 'locations.' .. location_id to use for location title")
  menu.last_location = location_id
  game:set_last_displayed_location(location_id)
  --Reset surfaces:
  menu.needs_two_lines = false
  menu.shrunken_font = false
  menu.title_surface:set_text("")
  menu.title_surface_line_2:set_text("")
  menu.title_surface:set_font_size(little_font_size)
  menu.title_surface_line_2:set_font_size(little_font_size)
  menu.big_title_surface:set_text("")
  menu.big_title_surface_line_2:set_text("")
  menu.big_title_surface:set_font_size(big_font_size)
  menu.big_title_surface_line_2:set_font_size(big_font_size)
  --Have we shown this before?
  if game:has_visited_location(location_id) then
    menu:set_title_text_accordingly(location_string, {menu.title_surface, menu.title_surface_line_2})
  else
    --Never been here before, use the big title:
    menu:set_title_text_accordingly(location_string, {menu.big_title_surface, menu.big_title_surface_line_2})
    game:set_visited_location(location_id, true)
  end
end



--Split the line in two at first space
local function split_at_space(str)
  local first_space = string.find(str, " ")
  return string.sub(str, 1, first_space - 1), string.sub(str, first_space + 1)
end


function menu:set_title_text_accordingly(location_string, surfaces)
  local surface_a, surface_b = surfaces[1], surfaces[2]

  surface_a:set_text(location_string)
  --If the line is too big, break it into two lines (if we can)
  if (surface_a:get_size() > screen_width - 48) and (location_string:match(" ")) then
    menu.needs_two_lines = true
    local line_1, line_2 = split_at_space(location_string)
    surface_a:set_text(line_1)
    surface_b:set_text(line_2)
  end
  --If the font is _still_ too big, make it smaller
  if (surface_a:get_size() > screen_width - 24) or (surface_b:get_size() > screen_width - 16) then
    menu.shrunken_font = true
    surface_a:set_font_size(surface_a:get_font_size() - font_shrink_amount)
    surface_b:set_font_size(surface_b:get_font_size() - font_shrink_amount)
  end
end


function menu:on_draw(dst)
  local centering_adjust = menu.shrunken_font and 8 or 0
  if menu.needs_two_lines then
    menu.title_surface:draw(dst, screen_width - 16, screen_height - 48 )
    menu.title_surface_line_2:draw(dst, screen_width - 16, screen_height - 16 )
    menu.big_title_surface:draw(dst, screen_width / 2, (screen_height / 2) - (32 - centering_adjust) )
    menu.big_title_surface_line_2:draw(dst, screen_width / 2, (screen_height / 2) + (32 - centering_adjust) )
  else
    menu.title_surface:draw(dst, screen_width - 16, screen_height - 16 )
    menu.big_title_surface:draw(dst, screen_width / 2, (screen_height / 4) * 2 )
  end
end



return manager
