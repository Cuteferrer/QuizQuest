--[[
Created by Max Mraz, licensed MIT
Manages item quickswapping
Usage:
- when equipping anything to a slow, call game:equip_active_quickslots()
- when each quickswap button is pressed, call game:quickswap(category)
- included categories are "item_1", "item_2", and "melee"
- I did not extract this to a config file, so you'll need to update this file to add other categories, but it should be pretty straightforward.
--]]

local game_meta = sol.main.get_metatable"game"

local max_slots = 3
local all_categories = {"melee", "item_1", "item_2"}


--Equips appropriate items based on active quickswap slots
--Call this whenever equipping anything to a slot
--Note: this does equip items for every category, so most of it is redundant whenever its called
function game_meta:equip_active_quickswap_slots()
  local game = self

  for _, category in pairs(all_categories) do
    local active_slot = game:get_quickswap_active_slot(category) or 1
    local new_item = game:get_quickswap_item(category, active_slot)
    if category == "melee" then
      game:set_value("equipped_weapon", new_item)
    elseif category == "item_1" then
      game:set_item_assigned(1, new_item and game:get_item(new_item) or nil)
    elseif category == "item_2" then
      game:set_item_assigned(2, new_item and game:get_item(new_item) or nil)
    end
  end

end

--Quickswap, should be called by by whichever button quickswap is assigned to
function game_meta:quickswap(category)
  local game = self
  assert(category, "Need to pass a category")
  local current_slot = game:get_quickswap_active_slot(category)
  local current_item = game:get_quickswap_item(category, current_slot)

  local new_slot, new_item = game:get_next_quickswap_item(category, current_slot)
  if (not new_item) then
    return --nothing is equipped at all for this category
  end

  game:set_quickswap_active_slot(category, new_slot)
  game:equip_active_quickswap_slots()

  if current_item ~= new_item then
    sol.audio.play_sound"inventory_quickswap"
  end
end


--Getters/setters
function game_meta:get_quickswap_item(category, slot)
  return self:get_value("quickswap_slot_" .. category .. "_" .. slot)
end

function game_meta:set_quickswap_item(category, slot, item_id)
  local game = self
  --If this item is already equipped to a different slot, unequip it
  local already_equipped_slot = nil
  for i = 1, max_slots do
    local already_item = game:get_quickswap_item(category, i)
    if already_item and already_item == item_id then
      game:set_quickswap_item(category, i, nil)
    end
  end
  game:set_value("quickswap_slot_" .. category .. "_" .. slot, item_id)
  game:equip_active_quickswap_slots() --equip active slots in case the currently active slot has been overwritten with a new item
end

function game_meta:get_quickswap_active_slot(category)
  return self:get_value("quickswap_active_slot_" .. category) or 1
end

function game_meta:set_quickswap_active_slot(category, new_slot)
  self:set_value("quickswap_active_slot_" .. category, new_slot)
end


--Get the next item in the category, skipping empty slots:
function game_meta:get_next_quickswap_item(category, current_slot)
  local game = self
  assert(category, "Need to pass a category")
  assert(current_slot, "Need to pass starting slot")
  --Short circuit if there's nothing equipped at all, otherwise we'd be in an infinite loop:
  if not game:anything_equipped_in_quickswap_category(category) then
    return
  end

  local i = current_slot
  local new_slot, new_item
  while not new_slot do
    i = (i % max_slots) + 1
    local itm = game:get_quickswap_item(category, i)
    if itm then
      new_slot = i
      new_item = itm
    end
  end

  return new_slot, new_item
end


--Check if all slots are empty:
function game_meta:anything_equipped_in_quickswap_category(category)
  local game = self
  local any_equipped = false
  for i = 1, max_slots do
    if game:get_quickswap_item(category, i) then
      any_equipped = true
      break
    end
  end
  return any_equipped
end


--Check if a given item in in a quickswap slot
--We assume you can't assign an item to multiple slots at once
--Returns: category, slot_no
function game_meta:is_item_in_quickswap_slot(item_id)
  local game = self
  for _, cat in pairs(all_categories) do
    for i = 1, max_slots do
      if game:get_quickswap_item(cat, i) == item_id then
        return cat, i
      end
    end
  end
  return false
end
