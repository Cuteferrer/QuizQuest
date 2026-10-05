local item_meta = sol.main.get_metatable("item")


function item_meta:get_max_amount_string()
  local save_name = self:get_name():gsub("/", "_")
  return save_name .. "_max_amount"
end

function item_meta:setup_amount_stuff(default_max_amount)
  --Uses item name to set savegame variable, amount variable, and max amount
  local item = self
  local game = item:get_game()

  default_max_amount = default_max_amount or 1
  local save_name = item:get_name():gsub("/", "_")
  item:set_savegame_variable("possession_" .. save_name)
  item:set_amount_savegame_variable("amount_" .. save_name)

  local max_amount = game:get_value(item:get_max_amount_string())
  if not max_amount then
    max_amount = default_max_amount
    game:set_value(item:get_max_amount_string(), default_max_amount)
  end
  item:set_max_amount(max_amount)
  item:set_assignable(true)
  item:set_ammo("_amount")
end

function item_meta:set_fill_on_checkpoint(refill_bool)
  if refill_bool == nil then refill_bool = true end
  local item = self
  local game = self:get_game()
  if not game.fill_on_checkpoint_items then game.fill_on_checkpoint_items = {} end
  game.fill_on_checkpoint_items[item:get_name()] = (refill_bool and item or nil)
end


--Returns an array of nearby enemies, sorted by distance to the hero (closest first) -- can be limited to X number of enemies with a second argument
function item_meta:select_nearby_enemies(range, limit)
  local map = self:get_map()
  local hero = map:get_hero()
  local x, y, z = hero:get_position()
  local enemies = {}
  local enemies_captured = 0

  for ent in map:get_entities_in_rectangle(x - range, y - range, range * 2, range * 2) do
    local distance = ent:get_distance(hero)
    if (ent:get_type() == "enemy") and (distance <= range) then
      enemies_captured = enemies_captured + 1
      ent.snedist = distance
      enemies[enemies_captured] = ent
    end
  end
  --Sort table by distance
  table.sort(enemies, function(a, b)
    return a.snedist < b.snedist
  end)
  --Truncate:
  local limited_enemies = {}
  for i = 1, limit do
    limited_enemies[i] = enemies[i]
  end

  return limited_enemies
end

