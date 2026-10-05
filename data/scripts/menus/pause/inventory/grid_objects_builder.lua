--[[
Takes in a list of item names (and a possible prefix) and returns a table of objects for a grid menu
Items with an amount will show it on their icon
The resulting objects will have description dialogs, sprites, and names for use with the trillium menu system description panel

Assumptions:
Name strings are located at "items.path.to.item"
Items have a description dialog (optional) at "item_descriptions.path.to.item"


Examples:
--Using no prefix:
local objects = manager.build_equipment_item_objects({
  "inventory/bombs",
  "inventory/bow",
  "weapons/sword",
  "weapons/spear"
})

--Using a prefix:
local objects = manager.build_equipment_item_objects({
  "bombs",
  "bow",
  "hookshot"
}, "inventory/")
--]]

local manager = {}

local equipped_marker_surface = sol.surface.load("sprites/menus/inventory/equipped_marker.png")

function manager.build_equipment_item_objects(possible_objects, prefix)
  prefix = prefix or ""
  local allowed_objects = {}
  for _, item_name in pairs(possible_objects) do
    local object = {}
    object.name = prefix .. item_name
    object.sprite = "_item"
    object.display_function = "_item"
    object.description_dialog = "item_descriptions." .. prefix:gsub("/", ".") .. item_name
    object.description_sprite = "entities/items"
    object.description_sprite_animation = prefix .. item_name
    object.text_function = function()
      local equip_item = sol.main.get_game():get_item(object.name)
      if equip_item and equip_item:has_amount() then
        return equip_item:get_amount()
      end
    end
    object.text_offset = { x = 16, y = 24}
    object.text_config = {
      font = "white_digits",
    }
    object.on_pre_draw = function(object, cell_surface, sprite, text_surface)
      local game = sol.main.get_game()
      local assigned_1 = game:get_item_assigned(1)
      local assigned_2 = game:get_item_assigned(2)
      if assigned_1 and assigned_1:get_name() == object.name then
        equipped_marker_surface:draw(cell_surface, 0, 0)
      elseif assigned_2 and assigned_2:get_name() == object.name then
        equipped_marker_surface:draw(cell_surface, 0, 0)
      elseif game:get_value("equipped_weapon") == object.name then
        equipped_marker_surface:draw(cell_surface, 0, 0)
      end
    end
    table.insert(allowed_objects, object)
  end
  return allowed_objects
end

return manager
