local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()

local dark_grey = sol.colors.ui_grey_dark

local menu = {x = 0, y = 0}
local width, height = 224, 160

local menu_surface = sol.surface.create()

local bg_surface = sol.modules.get_object("trilmenu_nineslice").get_surface{
  width = width, height = height,
  source_png = "menus/panel_blocks/small.png",
  tile_width = 8, tile_height = 8,
}

--[[
Attributes:
- name
- price
- quantity
- description  (dialogs --- item_short_descriptions.item_folder.item_id)
--]]

local name_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
}

local price_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
}

local quantity_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
}

local held_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
}

local type_surface = sol.text_surface.create{
  font = font,
  font_size = font_size,
}

local line = sol.surface.create(width - 16, 1)
line:fill_color(dark_grey)

local description_surface = sol.surface.create(width, height)



local function clear_text()
  name_surface:set_text""
  price_surface:set_text""
  quantity_surface:set_text""
  held_surface:set_text""
  type_surface:set_text""
  description_surface:clear()
  menu:update()
end

local function get_itype(name)
  local exact_matches = {
    ["collectibles/keys"] = "items.item_types.key",
    ["collectibles/crafting_book"] = "items.item_types.key_item",
    ["collectibles/relics"] = "items.item_types.relic"
  }

  local type_table = {
    charms = "items.item_types.charm",
    collectibles = "items.item_types.upgrade",
    consumables = "items.item_types.consumable",
    guns = "items.item_types.gun",
    solforge = "items.item_types.weapon",
    spells = "items.item_types.spell",
    spell_eyes = "items.item_types.eye",
    inventory = "items.item_types.tool"
  }

  for itype, itype_string in pairs(exact_matches) do
    if name:match(itype) then
      return sol.language.get_string(itype_string)
    end
  end

  for itype, itype_string in pairs(type_table) do
    if string.find(name, itype) then
      return sol.language.get_string(itype_string)
    end
  end

  return ""

end

function menu:notify(parent)
  local game = sol.main.get_game()
  local sel_ob = parent:get_selected_object()
  if not sel_ob then
    clear_text()
    return
  end
  local item = game:get_item(sel_ob.name)
  local name = sel_ob.name:gsub("/", ".")
  --for example: "inventory/healing_flask"
  name_surface:set_text(sol.language.get_string("items." .. name))
  type_surface:set_text(sol.language.get_string("menu.shop.type_label") .. " " .. get_itype(sel_ob.name))
  price_surface:set_text(sol.language.get_string("menu.shop.price_label") .. " " .. sel_ob.price)
  --Show quantity in stock:
  if sel_ob.quantity then
    quantity_surface:set_text(sol.language.get_string("menu.shop.quantity_label") .. " " .. sel_ob.quantity)
  else
    quantity_surface:set_text("")
  end
  --Show amount held:
  if item:has_amount() then
    held_surface:set_text(sol.language.get_string("menu.shop.held_label") .. " " .. item:get_amount())
  else
    held_surface:set_text("")
  end
  --Create desription text:
  local description_name = name:gsub("solforge.", "weapons.")
  sol.surface.stamp_text({
    dst_surface = description_surface,
    dialog_id = "item_descriptions." .. description_name,
    vertical_spacing = 12,
  })
  menu:update()
end


function menu:update()
  local displaying_quantity = quantity_surface:get_text() ~= ""
  menu_surface:clear()
  bg_surface:draw(menu_surface)
  name_surface:draw(menu_surface, 8, 16)
  type_surface:draw(menu_surface, 8, 34)
  price_surface:draw(menu_surface, 8, 52)
  quantity_surface:draw(menu_surface, 160, 52)
  held_surface:draw(menu_surface, 160, 16)
  line:draw(menu_surface, 8, 64)
  description_surface:draw(menu_surface, 8, 72)

end




function menu:on_draw(dst)
  menu_surface:draw(dst, menu.x, menu.y)
end


return menu
