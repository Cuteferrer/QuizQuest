local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()

local menu = {}

local menu_duration = 4000 --how long the popup will last on its own
local screen_width, screen_height = sol.video.get_quest_size()
local width, height = 208, 56
local menu = {x = screen_width / 2 - width / 2, y = screen_height - height - 8}

local menu_surface = sol.surface.create()

local bg_surface = sol.modules.get_object("trilmenu_nineslice").get_surface{
  width = width, height = height,
  source_png = "menus/panel_blocks/small.png",
  tile_width = 8, tile_height = 8,
}

local item_sprite = sol.sprite.create"entities/items"
item_sprite:set_animation"empty"

local name_surface = sol.text_surface.create{
  font = font, font_size = font_size,
  vertical_alignment = "top",
  horizontal_alignment = "center",
}

local category_surface = sol.text_surface.create{
  font = font, font_size = font_size,
  vertical_alignment = "top",
  horizontal_alignment = "right",
  color = {100,100,80},
}

local line_break = sol.surface.create(width - 32, 1)
line_break:fill_color({100,100,80})


function menu:get_item_category(item_id)
  local prefix_matcher = {
    ["charms/"] = "charm",
    ["consumables/"] = "consumable",
    ["materials/crafting/"] = "crafting_material",
    ["gear/"] = "equipment",
    ["spell_eyes/"] = "eye",
    ["guns/"] = "gun",
    ["collectibles/keys/"] = "key",
    --["charms/"] = "key_item",
    ["collectibles/mirror_shard"] = "key_item",
    ["collectibles/misc"] = "key_item",
    ["collectibles/relics/"] = "relic",
    ["spells/"] = "spell",
    ["inventory/"] = "tool",
    ["potions/"] = "potion",
    --["charms/"] = "upgrade",
    ["solforge/"] = "weapon",
  }

  local category
  for prefix, cat in pairs(prefix_matcher) do
    if item_id:match(prefix) then category = cat end
  end
  return category
end


function menu:set_item(item_id, variant)
  variant = variant or 1
  menu.item_id = item_id
  item_sprite:set_animation(item_id)
  item_sprite:set_direction(variant - 1)
  local name = sol.language.get_string( "items." .. item_id:gsub("/", ".") )
  name_surface:set_text(name or "")
  local item_category = menu:get_item_category(item_id) or ""
  category_surface:set_text(sol.language.get_string("items.item_types." .. item_category))
  local name_width, name_height = name_surface:get_size()

  --Draw elements:
  menu_surface:clear()
  bg_surface:draw(menu_surface)
  name_surface:draw(menu_surface, width / 2, 4) --centered top
  --name_surface:draw(menu_surface, 40, height - 28) --side of item sprite
  item_sprite:draw(menu_surface, width / 2, height - 16) --centered
  --item_sprite:draw(menu_surface, 24, height - 16) --left side
  category_surface:draw(menu_surface, width - 16, 19) --below line, right side
  --category_surface:draw(menu_surface, 16, 4) --above line, left side
  line_break:draw(menu_surface, 16, 18)
end


function menu:on_started()
  sol.timer.start(menu, menu_duration, function()
    if sol.menu.is_started(menu) then sol.menu.stop(menu) end
  end)
end


function menu:on_draw(dst)
  menu_surface:draw(dst, menu.x, menu.y)
end


function menu:on_command_pressed(command)
  local handled = false
  if (command == "confirm") then
    sol.menu.stop(menu)
    local handled = true
  end
  return handled
end

return menu
