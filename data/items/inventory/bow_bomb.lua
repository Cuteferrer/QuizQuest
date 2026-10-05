local item = ...
local game = item:get_game()

function item:on_started()
  item:set_savegame_variable("possession_bow_fire")
  item:set_assignable(true)
  item:set_ammo("_magic")
end

function item:on_using()
  if not item:try_spend_ammo(20) then
    item:set_finished()
    return
  end
  local slot_assigned = (game:get_item_assigned(1) == item and 1 or 2)
  game:get_item("inventory/bow"):on_using({
    arrow_type = "bomb",
    slot_assigned = slot_assigned
  })
end